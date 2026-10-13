"""Test rapido delle novita' di giocabilita' (fuga finale, tempo in scadenza,
bonus tempo, avviso di fine super potere, combo "partita perfetta", levette di difficolta').

Uso:
  xvfb-run -a -s "-screen 0 800x600x24" python3 test_features.py . "../bin/Snack and Roll.bas.bin" /tmp/screenshot
"""
import os
import sys

sys.path.insert(0, sys.argv[1])
from snr import *  # noqa

ROM = sys.argv[2]
OUT = sys.argv[3]
os.makedirs(OUT, exist_ok=True)
PFSCORECOLOR = 0xF4
FAIL = []


def check(name, ok, detail=""):
    print(("  ok   " if ok else "  FAIL ") + name + (f"  ({detail})" if detail else ""), flush=True)
    if not ok:
        FAIL.append(name)


def frames(r1, r2):
    return (r2.v("seconds") - r1.v("seconds")) * 48 + r2.v("frame") - r1.v("frame")


def music_rate(s, seconds=1.5):
    """frame per passo della musica di gioco."""
    r1 = s.save()
    s.wait(seconds)
    r2 = s.save()
    steps = (r2.v("music") - r1.v("music")) & 31
    return frames(r1, r2) / max(steps, 1)


def mouth_rate(s, seconds=1.5):
    """frame per passo della bocca 0 (si muove verso il biscotto lontano)."""
    r1 = s.save()
    s.wait(seconds)
    r2 = s.save()
    steps = abs(r2.v("mouth0x") - r1.v("mouth0x"))
    return frames(r1, r2) / max(steps, 1)


s = Stella(ROM, "feat")
try:
    s.tap("F2", 0.3)          # reset: parte il livello 1
    s.wait(1.5)
    r = s.save()
    check("partita iniziata al livello 1", r.v("level") == 1 and r.flag(0) == 1, f"level={r.v('level')}")

    # --- musica normale e bocca normale ---
    s.poke({V["hitCooldown"]: 250, PFSCORE1: 0xFF})
    rate = music_rate(s)
    check("musica normale: un passo ogni 8 frame", 7 <= rate <= 9, f"{rate:.1f} frame/passo")

    # --- tempo in scadenza ---
    s.poke({PFSCORE1: 0xC0, V["hitCooldown"]: 250})
    rate = music_rate(s)
    check("tempo in scadenza: musica al doppio (un passo ogni 4 frame)", 3.5 <= rate <= 4.5, f"{rate:.1f}")
    cols = set()
    for _ in range(25):
        cols.add(s.save()[PFSCORECOLOR])
        s.wait(0.04)
    check("tempo in scadenza: la barra lampeggia in rosso", {0x08, 0x64} <= cols, f"colori={sorted(cols)}")
    s.shot(f"{OUT}/tempo_in_scadenza.png")
    s.poke({PFSCORE1: 0xFF, V["hitCooldown"]: 250})
    cols = {s.save()[PFSCORECOLOR] for _ in range(10)}
    check("tempo pieno: barra normale", cols == {0x08}, f"colori={sorted(cols)}")

    # --- bocca: velocita' normale e nella fuga finale ---
    s.poke({PLAYER0X: 140, PLAYER0Y: 84, V["mouth0x"]: 20, V["mouth0y"]: 84,
            V["hitCooldown"]: 0, PFSCORE1: 0xFF})
    rate_n = mouth_rate(s)
    s.poke({PLAYER0X: 140, PLAYER0Y: 84, V["mouth0x"]: 20, V["mouth0y"]: 84,
            BALLY: 28, BALLX: 18, PFSCORE1: 0xFF})
    rate_f = mouth_rate(s)
    check("fuga finale: le bocche vanno al doppio", 11 <= rate_n <= 13 and 5 <= rate_f <= 7,
          f"normale {rate_n:.1f}, fuga {rate_f:.1f} frame/passo")
    s.poke({PLAYER0X: 140, PLAYER0Y: 84, V["mouth0x"]: 20, V["mouth0y"]: 84,
            BALLY: 28, BALLX: 18, V["hitCooldown"]: 250})
    rate = music_rate(s)
    check("fuga finale: musica al doppio", 3.5 <= rate <= 4.5, f"{rate:.1f}")

    # --- bonus tempo al cambio di livello ---
    r = s.save()
    s.poke({PFSCORE1: 0xFF, SCORE: 0, SCORE + 1: 0, SCORE + 2: 0, V["hitCooldown"]: 250,
            V["choco_bits"]: 0xFF, V["choco_count"]: 8, BALLY: 28, BALLX: 18,
            PLAYER0X: 14, PLAYER0Y: 30})
    s.wait(0.3)
    mid = s.save()
    s.wait(2.0)
    r = s.save()
    check("bonus tempo: la barra si svuota un segmento alla volta",
          mid.v("level") == 1 and mid[PFSCORE1] not in (0, 0xFF) and 0 < mid.score() < 160,
          f"a meta': barra={mid[PFSCORE1]:08b} punti={mid.score()} livello={mid.v('level')}")
    check("bonus tempo: 8 segmenti x 20 = 160 punti, poi livello 2",
          r.v("level") == 2 and r.score() == 160 and r[PFSCORE1] == 0xFF,
          f"livello={r.v('level')} punti={r.score()} barra={r[PFSCORE1]:08b}")

    # --- combo "partita perfetta": zuccherino doppio senza vite perse ---
    from model import sugar_xy
    mx, my = sugar_xy(51)      # livello 2, terzo zuccherino (data sugar)
    for lives, exp in ((0xAA, 100), (0x2A, 50)):
        s.poke({SCORE: 0, SCORE + 1: 0, SCORE + 2: 0, PFSCORE2: lives, V["hitCooldown"]: 250,
                V["choco_bits"]: 3, V["choco_count"]: 2, PLAYER0X: mx - 4, PLAYER0Y: my + 2})
        s.wait(0.3)
        r = s.save()
        check(f"zuccherino con vite {lives:08b}: {exp} punti", r.score() == exp and r.v("choco_bits") == 7,
              f"punti={r.score()} bits={r.v('choco_bits'):08b}")

    # --- zuccherini: dorato giallo, chiave azzurra ---
    s.poke({V["hitCooldown"]: 250, V["choco_bits"]: 0, PLAYER0X: 140, PLAYER0Y: 84})
    s.wait(0.3)
    s.shot(f"{OUT}/zuccherino_dorato.png")
    s.poke({V["hitCooldown"]: 250, V["choco_bits"]: 1, PLAYER0X: 140, PLAYER0Y: 84})
    s.wait(0.3)
    s.shot(f"{OUT}/zuccherino_chiave.png")

    # --- fine super potere: il cooldown scende fino a 0 ---
    s.poke({V["hitCooldown"]: 60, V["sfxId"]: 0})
    s.wait(1.6)
    r = s.save()
    check("super potere: finisce dopo l'avviso", r.v("hitCooldown") == 0, f"cooldown={r.v('hitCooldown')}")

    # --- levette di difficolta' (Stella: F5/F6 sinistra A/B, F7/F8 destra A/B) ---
    # si leggono a inizio livello: si passa al livello successivo col sacchetto
    def next_level(ballx):
        s.poke({PFSCORE1: 0xFF, SCORE: 0, SCORE + 1: 0, SCORE + 2: 0, V["hitCooldown"]: 250,
                V["choco_bits"]: 0xFF, V["choco_count"]: 8, BALLY: 28, BALLX: ballx,
                PLAYER0X: ballx - 4, PLAYER0Y: 30})
        s.wait(2.5)
        return s.save()
    s.tap("F5", 0.2)
    s.tap("F7", 0.2)
    r = next_level(136)          # livello 2 -> 3, levette in A
    check("levette in A: livello 3, bocche piu' veloci (9-2=7 frame per passo), 6 tacche, niente bonus",
          r.v("level") == 3 and r.v("speed") == 7 and r[PFSCORE1] == 0xFC and r.score() == 0,
          f"livello={r.v('level')} speed={r.v('speed')} tempo={r[PFSCORE1]:08b} punti={r.score()}")
    s.tap("F6", 0.2)
    s.tap("F8", 0.2)
    r = next_level(18)           # livello 3 -> 4, levette in B
    check("levette in B: livello 4 normale (8 frame per passo, 8 tacche, bonus 160)",
          r.v("level") == 4 and r.v("speed") == 8 and r[PFSCORE1] == 0xFF and r.score() == 160,
          f"livello={r.v('level')} speed={r.v('speed')} tempo={r[PFSCORE1]:08b} punti={r.score()}")
finally:
    s.close()

print("TUTTO OK" if not FAIL else f"FALLITI: {FAIL}")
sys.exit(1 if FAIL else 0)
