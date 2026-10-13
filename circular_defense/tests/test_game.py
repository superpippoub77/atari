"""Test della ROM Atari di Circular Defense nell'emulatore Stella.

Uso (serve Stella, xdotool, ImageMagick e xvfb-run):
  xvfb-run -a -s "-screen 0 800x600x24" python3 test_game.py . "../bin/Circular Defense.bas.bin" /tmp/screenshot

Controlla: attesa iniziale, avvio col fuoco, velocita' dello scudo con la
levetta, cannone, scudo che ferma i proiettili, blocchi distrutti (anche
quello piu' vicino se il bersaglio e' gia' caduto), ondate, game over,
nuova partita e levette di difficolta'.
"""
import os
import subprocess
import sys

sys.path.insert(0, sys.argv[1])
from cdh import *  # noqa

ROM = sys.argv[2]
OUT = sys.argv[3]
os.makedirs(OUT, exist_ok=True)
RESULTS = []

# BAS: data blkcol / blkrow (tools/gen_tables.py)
BLKCOL = [29, 27, 22, 15, 8, 3, 1, 3, 8, 15, 22, 27]
BLKROW = [5, 8, 9, 10, 9, 8, 5, 2, 1, 0, 1, 2]


def check(name, ok, detail=""):
    RESULTS.append((name, bool(ok), detail))
    print(("  ok   " if ok else "  FAIL ") + name + (f"  ({detail})" if detail else ""), flush=True)


def grab(s, name):
    wid = subprocess.run(["xdotool", "search", "--pid", str(s.p.pid)], capture_output=True, text=True).stdout.split()[-1]
    subprocess.run(["import", "-window", wid, f"{OUT}/{name}.png"])


def ring(r):
    """Blocchi disegnati nel playfield (entrambi i pixel accesi)."""
    return [d for d in range(12) if r.pf(BLKCOL[d], BLKROW[d]) and r.pf(BLKCOL[d] + 1, BLKROW[d])]


def spin(s, keys, seconds=0.3):
    """Unita' d'angolo per frame dello scudo tenendo premuti i tasti
    (finestra breve: in piu' di mezzo giro la differenza d'angolo si
    riavvolge su 256 e la misura diventerebbe ambigua)."""
    if keys:
        s.down(*keys)
    s.wait(0.2)
    r1 = s.save()
    s.wait(seconds)
    r2 = s.save()
    if keys:
        s.up(*keys)
    frames = (r2.v("frame") - r1.v("frame")) & 255
    da = (r2.v("angle") - r1.v("angle")) & 255
    if da > 127:
        da -= 256
    return da / max(frames, 1)


def bullet(s, d, t, extra=None):
    """Mette il proiettile 0 in direzione d al passo t (posizione esatta)."""
    vx = (BLKCOL[d] * 4 + 22 - 82) * 4      # 1/256 di pixel per passo
    vy = (BLKROW[d] * 8 + 4 - 44) * 4
    x = 82 * 256 + vx * t
    y = 44 * 256 + vy * t
    vals = {V["b0x"]: x >> 8, V["b0x"] + 1: x & 255, V["b0y"]: y >> 8, V["b0y"] + 1: y & 255,
            V["b0d"]: d, V["b0t"]: t, V["b1t"]: 255, V["spawnT"]: 0, V["interval"]: 250}
    vals.update(extra or {})
    s.poke(vals)


def sfx_seen(s, seconds):
    seen = set()
    t0 = time.time()
    while time.time() - t0 < seconds:
        seen.add(s.save().v("sfxId"))
        s.wait(0.04)
    seen.discard(0)
    return seen


def main():
    s = Stella(ROM, "game")
    try:
        # --- attesa iniziale ---
        s.wait(1.0)
        r = s.save()
        check("attesa: partita non iniziata, anello di 12 blocchi", r.v("state") & 1 == 0 and ring(r) == list(range(12)),
              f"blocchi={ring(r)}")
        rate = spin(s, None, 1.2)
        check("attesa: lo scudo gira piano da solo (0,5 unita'/frame)", 0.35 <= rate <= 0.65, f"{rate:.2f}")
        grab(s, "cd_attesa")

        # --- avvio ---
        s.tap("space", 0.2)
        s.wait(0.4)
        r = s.save()
        check("fuoco: inizia la partita (ondata 1, punteggio 0, cannone ogni 75 frame)",
              r.v("state") & 1 and r.v("wave") == 1 and r.score() == 0 and 70 <= r.v("interval") <= 75,
              f"stato={r.v('state')} ondata={r.v('wave')} intervallo={r.v('interval')}")

        # --- velocita' dello scudo ---
        for keys, lo, hi, name in ((None, 1.3, 1.7, "da solo 1,5"), (["Right"], 3.2, 3.8, "destra 3,5 (piu' veloce)"),
                                   (["Left"], -2.8, -2.2, "sinistra -2,5 (all'indietro)"),
                                   (["space"], 0.35, 0.65, "fuoco 0,5 (freno)")):
            s.poke({V["alive0"]: 255, V["alive1"]: 15, V["b0t"]: 255, V["b1t"]: 255, V["spawnT"]: 0, V["interval"]: 250})
            rate = spin(s, keys)
            check(f"scudo: {name} unita'/frame", lo <= rate <= hi, f"{rate:.2f}")

        # --- cannone ---
        s.poke({V["spawnT"]: 0, V["interval"]: 40, V["b0t"]: 255, V["b1t"]: 255})
        heard = sfx_seen(s, 1.2)
        r = s.save()
        check("il cannone spara (proiettile in volo, suono dello sparo)",
              (r.v("b0t") != 255 or r.v("b1t") != 255) and 1 in heard, f"passi={r.v('b0t')},{r.v('b1t')} suoni={sorted(heard)}")
        grab(s, "cd_partita")

        # --- lo scudo ferma il proiettile ---
        r = s.save()
        score0 = r.score()
        s.down("space")                      # freno: lo scudo resta quasi fermo
        bullet(s, 0, 24, {V["angle"]: 254})
        heard = sfx_seen(s, 1.0)
        s.up("space")
        r = s.save()
        check("lo scudo ferma il proiettile: +1, nessun blocco perso, suono",
              r.score() == score0 + 1 and r.v("b0t") == 255 and r.alive() == 12 and 2 in heard,
              f"punti {score0}->{r.score()} blocchi={r.alive()} suoni={sorted(heard)}")

        # --- il proiettile distrugge il blocco ---
        bullet(s, 0, 58, {V["angle"]: 128})
        heard = sfx_seen(s, 0.6)
        r = s.save()
        check("proiettile all'anello: il blocco 0 sparisce (memoria e schermo), suono",
              not r.v("alive0") & 1 and 0 not in ring(r) and r.alive() == 11 and 3 in heard,
              f"blocchi={ring(r)} suoni={sorted(heard)}")
        bullet(s, 0, 58, {V["angle"]: 128})
        s.wait(0.6)
        r = s.save()
        check("blocco gia' distrutto: cade il piu' vicino (blocco 1)",
              not r.v("alive0") & 2 and 1 not in ring(r) and r.alive() == 10, f"blocchi={ring(r)}")
        grab(s, "cd_blocchi_persi")

        # --- ondate ---
        r = s.save()
        s.down("space")
        bullet(s, 3, 24, {V["angle"]: 62, V["blocked"]: 9})
        s.wait(1.0)
        s.up("space")
        r = s.save()
        check("10 proiettili fermati: ondata 2, barra delle ondate a 2 segmenti",
              r.v("wave") == 2 and r[PFSCORE1] == 0b11 and r.v("blocked") == 0,
              f"ondata={r.v('wave')} barra={r[PFSCORE1]:08b}")

        # --- game over ---
        bullet(s, 6, 58, {V["angle"]: 0, V["alive0"]: 64, V["alive1"]: 0})
        heard = sfx_seen(s, 0.8)
        r = s.save()
        check("ultimo blocco distrutto: citta' distrutta (game over), sirena",
              r.v("state") & 3 == 2 and r.alive() == 0 and 4 in heard, f"stato={r.v('state')} suoni={sorted(heard)}")
        grab(s, "cd_game_over")
        s.wait(1.5)
        r = s.save()
        check("dopo il game over il cannone non spara piu'", r.v("b0t") == 255 and r.v("b1t") == 255)
        s.tap("space", 0.2)
        s.wait(0.5)
        r = s.save()
        check("fuoco: nuova partita con l'anello intero e il punteggio azzerato",
              r.v("state") & 1 and r.alive() == 12 and ring(r) == list(range(12)) and r.score() == 0,
              f"stato={r.v('state')} blocchi={ring(r)} punti={r.score()}")

        # --- levette di difficolta' (Stella: F5/F6 sinistra A/B, F7/F8 destra A/B) ---
        s.poke({V["alive0"]: 0, V["alive1"]: 0, V["state"]: 2 | 128})   # torna in attesa
        s.wait(0.3)
        s.tap("F5", 0.2)
        s.tap("F7", 0.2)
        s.tap("F2", 0.2)                                                  # Reset
        s.wait(0.4)
        r = s.save()
        check("levetta destra A: il cannone parte piu' rapido (50 frame)", 45 <= r.v("interval") <= 50,
              f"intervallo={r.v('interval')}")
        s.poke({V["acc"]: 0, V["b1t"]: 255, V["spawnT"]: 0, V["interval"]: 250})
        bullet(s, 0, 0, {V["angle"]: 128, V["acc"]: 0})
        r1 = s.save()
        s.wait(0.5)
        r2 = s.save()
        fa = ((r2.v("frame") - r1.v("frame")) & 255)
        sa = (r2.v("b0t") - r1.v("b0t")) / max(fa, 1)
        s.tap("F6", 0.2)
        s.tap("F8", 0.2)
        bullet(s, 0, 0, {V["angle"]: 128, V["acc"]: 0})
        r1 = s.save()
        s.wait(0.5)
        r2 = s.save()
        fb = ((r2.v("frame") - r1.v("frame")) & 255)
        sb = (r2.v("b0t") - r1.v("b0t")) / max(fb, 1)
        check("levetta sinistra A: proiettili piu' veloci (9/8 contro 7/8 passi per frame)",
              1.0 <= sa <= 1.25 and 0.75 <= sb <= 0.95, f"A {sa:.2f}, B {sb:.2f}")
    finally:
        s.close()

    fails = [x for x in RESULTS if not x[1]]
    print(f"\nRISULTATO: {len(RESULTS) - len(fails)}/{len(RESULTS)} controlli superati")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
