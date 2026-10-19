"""Test di OXYGEN 2600 in Stella: meccaniche principali del primo livello.

Uso:  xvfb-run -a python3 test_oxygen.py <rom> <cartella screenshot>
"""
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from oxy import (BALLX, BALLY, MISSILE1X, MISSILE1Y, PFSCORE2, PLAYER0X, PLAYER0Y,  # noqa: E402
                 Stella, V, grab)

ROM, OUT = sys.argv[1], sys.argv[2]
RESULTS = []


def check(name, ok, detail=""):
    RESULTS.append((name, bool(ok), detail))
    print(("  ok   " if ok else "  FAIL ") + name + (f"  ({detail})" if detail else ""), flush=True)
    return ok


def touch_ball(s, r):
    """mette il giocatore sopra la ball e aspetta un attimo."""
    s.poke({PLAYER0X: r[BALLX] - 3, PLAYER0Y: r[BALLY] + 3})
    s.wait(0.3)
    return s.save()


def main():
    s = Stella(ROM, "oxy")
    s.wait(1)
    r = s.save()
    grab(s, f"{OUT}/titolo.png")
    s.tap("space", 0.15)
    s.wait(1.0)
    r = s.save()
    check("parte il livello 1 nella stanza della base di partenza", r.v("level") == 0 and r.v("room") == 0,
          f"livello={r.v('level')} stanza={r.v('room')}")
    check("si parte dentro la base, con l'ossigeno pieno (normal: 30 s)",
          r.flag(0) == 1 and r.v("o2") == 120, f"flags={r.v('flags'):08b} o2={r.v('o2')}")
    grab(s, f"{OUT}/livello1.png")
    s.wait(1.0)
    r2 = s.save()
    check("dentro la base l'ossigeno non cala", r2.v("o2") == 120, f"o2={r2.v('o2')}")

    # fuori dalla base (porta a destra, riga centrale)
    s.poke({PLAYER0X: 70, PLAYER0Y: 24})
    s.wait(1.5)
    r = s.save()
    check("fuori dalla base l'ossigeno cala", r.flag(0) == 0 and r.v("o2") < 120,
          f"flags={r.v('flags'):08b} o2={r.v('o2')}")

    # chiave
    r = s.save()
    check("nella stanza c'e' la prima chiave", r.v("ball") == 1, f"ball={r.v('ball')} ({r[BALLX]},{r[BALLY]})")
    score0 = r.score()
    r = touch_ball(s, r)
    check("toccando la chiave la si prende (+300)", r.flag(2) == 1 and r.score() == score0 + 300,
          f"flags={r.v('flags'):08b} punti {score0}->{r.score()}")
    check("presa la chiave, nella stanza resta la bombola della base", r.v("ball") == 3, f"ball={r.v('ball')}")

    # nemico: colpi fino a ucciderlo
    r = s.save()
    ex, ey, info = r.v("ex0"), r.v("ey0"), r.v("einfo0")
    check("c'e' una guardia nella stanza", info & 0x80 and info & 3 == 0, f"({ex},{ey}) info={info:08b}")
    hits = 0
    for _ in range(30):
        r = s.save()
        if not r.v("einfo0") & 0x80:
            break
        # a sinistra del nemico, sulla stessa riga, guardando a destra
        s.poke({PLAYER0X: max(20, r.v("ex0") - 16), PLAYER0Y: r.v("ey0"), V["hitCool"]: 200,
                V["dir"]: 2, V["flags"]: r.v("flags") & ~0x02, V["o2"]: 120})
        s.down("space")
        s.wait(0.05)
        s.up("space")
        s.wait(0.5)
        hits += 1
    r = s.save()
    check("la guardia muore dopo i suoi colpi (+100 a colpo, +500)", not r.v("einfo0") & 0x80 and r.v("dead") & 1,
          f"colpi={hits} info={r.v('einfo0'):08b} morti={r.v('dead'):08b}")

    # stanza a destra
    s.poke({PLAYER0X: 140, PLAYER0Y: 24, V["hitCool"]: 200})
    s.hold(["Right"], 0.4)
    r = s.save()
    check("dal bordo destro si passa nella stanza accanto", r.v("room") == 1 and r[PLAYER0X] < 30,
          f"stanza={r.v('room')} x={r[PLAYER0X]}")
    grab(s, f"{OUT}/stanza2.png")

    # colpo nemico: -3 secondi di ossigeno
    r = s.save()
    s.poke({V["o2"]: 100, V["hitCool"]: 0, MISSILE1X: r[PLAYER0X] + 3, MISSILE1Y: r[PLAYER0Y] - 2,
            V["flags"]: r.v("flags") | 0x10, V["bulletDir"]: 0})
    s.wait(0.3)
    r = s.save()
    check("un colpo nemico toglie 3 secondi di ossigeno", r.v("o2") <= 88, f"o2={r.v('o2')}")

    # vita persa con l'ossigeno finito
    lives0 = r[PFSCORE2]
    s.poke({V["o2"]: 1, V["o2tick"]: 0, V["hitCool"]: 200, V["flags"]: r.v("flags") & ~0x01})
    s.wait(1.0)
    r = s.save()
    check("ossigeno finito: si perde una vita e si riparte dalla base", r[PFSCORE2] == lives0 // 4 and
          r.v("room") == 0 and r.flag(0) == 1 and r.v("o2") == 120,
          f"vite {lives0:08b}->{r[PFSCORE2]:08b} stanza={r.v('room')} o2={r.v('o2')}")
    check("la chiave presa resta presa", r.flag(2) == 1, f"flags={r.v('flags'):08b}")
    check("la guardia uccisa resta morta", not r.v("einfo0") & 0x80, f"info={r.v('einfo0'):08b}")

    # bombola: ricarica dentro la base (sicura: +15 s)
    s.poke({V["o2"]: 40})
    s.wait(0.2)
    r = s.save()
    r = touch_ball(s, r)
    check("la bombola della base sicura ricarica 15 secondi", r.v("o2") >= 95, f"o2={r.v('o2')} ball={r.v('ball')}")

    # interruttore: con tutte e due le chiavi nella base finale (stanza 3)
    s.poke({V["flags"]: r.v("flags") | 0x0C, V["room"]: 3, PLAYER0X: 80, PLAYER0Y: 24})
    s.poke({PLAYER0X: 20, PLAYER0Y: 24})
    s.hold(["Left"], 0.2)
    r = s.save()
    # (passando da una stanza si ricarica quella nuova: entra dalla stanza 2)
    s.poke({V["room"]: 2, PLAYER0X: 140, PLAYER0Y: 24})
    s.hold(["Right"], 0.4)
    r = s.save()
    print("\n".join("     " + x for x in r.pf_rows()))
    grab(s, f"{OUT}/base_finale.png")
    check("nella base finale c'e' l'interruttore e il cancello e' aperto", r.v("ball") == 4,
          f"stanza={r.v('room')} ball={r.v('ball')} ({r[BALLX]},{r[BALLY]})")
    score0 = r.score()
    r = touch_ball(s, r)
    s.wait(2.5)
    r = s.save()
    check("l'interruttore con le 2 chiavi finisce il livello (+5000) e parte il livello 2",
          r.v("level") == 1 and r.score() >= score0 + 5000, f"livello={r.v('level')} punti {score0}->{r.score()}")
    grab(s, f"{OUT}/livello2.png")
    s.close()

    fails = [x for x in RESULTS if not x[1]]
    print(f"\nRISULTATO: {len(RESULTS) - len(fails)}/{len(RESULTS)} controlli superati")
    for f in fails:
        print("  FAIL", f)
    return not fails


if __name__ == "__main__":
    sys.exit(0 if main() else 1)
