"""Test della ROM Atari di Circular Defense nell'emulatore Stella.

Uso (serve Stella, xdotool, ImageMagick e xvfb-run):
  xvfb-run -a -s "-screen 0 800x600x24" python3 test_game.py . "../bin/Circular Defense.bas.bin" /tmp/screenshot

Controlla: titolo con la scritta e la musica, scelta del controller con
Select, paddle (posizione assoluta) e joystick (niente movimento
automatico), inizio partita, colpi parati, citta' che perdono un pezzetto
alla volta (dall'alto), citta' distrutte, fine livello con il bonus, colpi
deviati, buio, game over, vittoria e levette di difficolta'.
"""
import os
import subprocess
import sys
import time

sys.path.insert(0, sys.argv[1])
sys.path.insert(0, os.path.join(sys.argv[1], "..", "tools"))
from cdh import *  # noqa
import gen_tables  # noqa
import gen_text  # noqa

ROM = sys.argv[2]
OUT = sys.argv[3]
os.makedirs(OUT, exist_ok=True)
RESULTS = []

PIECES = gen_tables.pieces()                      # [citta'][pezzetto] = (colonna, riga)
VX, VY, TCITY, AIM = gen_tables.velocities()
LVQUOTA = [0, 8, 10, 12, 12, 14, 14, 16, 20]       # BAS: data lvquota
LVINT = [0, 80, 70, 65, 60, 55, 50, 45, 40]        # BAS: data lvint
LVSPEED = [0, 6, 7, 8, 8, 10, 10, 12, 14]          # BAS: data lvspeed


def check(name, ok, detail=""):
    RESULTS.append((name, bool(ok), detail))
    print(("  ok   " if ok else "  FAIL ") + name + (f"  ({detail})" if detail else ""), flush=True)


def grab(s, name):
    wid = subprocess.run(["xdotool", "search", "--pid", str(s.p.pid)], capture_output=True, text=True).stdout.split()[-1]
    subprocess.run(["import", "-window", wid, f"{OUT}/{name}.png"])


def lit(r, city):
    """pezzetti ancora in piedi della citta'."""
    return [k for k, (c, row) in enumerate(PIECES[city]) if c != 255 and r.pf(c, row)]


def all_lit(r):
    return sum(len(lit(r, k)) for k in range(6))


def text_on_screen(r, rows):
    return all((r.pf(c, rr) == 1) == (rows[rr][c] == "X") for rr in range(11) for c in range(32))


def bullet(s, v, t, extra=None):
    """mette il proiettile 0 con velocita' v al passo t, nella posizione esatta
    (prima si salva: poke riscrive l'ultimo salvataggio di Stella)."""
    s.save()
    if v < 6:
        x = 82 * 256 + round(VX[v]) * t
        y = 44 * 256 + round(VY[v]) * t
    else:
        d = (v - 6) // 2
        x = 82 * 256 + round(VX[d]) * 32 + round(VX[v]) * (t - 32)
        y = 44 * 256 + round(VY[d]) * 32 + round(VY[v]) * (t - 32)
    vals = {V["b0x"]: (x >> 8) & 255, V["b0x"] + 1: x & 255, V["b0y"]: (y >> 8) & 255, V["b0y"] + 1: y & 255,
            V["b0v"]: v, V["b0t"]: t, V["b1t"]: 255, V["spawnT"]: 0, V["interval"]: 250}
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


def far_angle(city):
    """angolo del difensore dalla parte opposta alla citta'."""
    return (round(gen_tables.CITY_ANGLES[city] * 256 / 360) + 128) & 255


def spin(s, keys, seconds=0.3):
    if keys:
        s.down(*keys)
    s.wait(0.15)
    r1 = s.save()
    s.wait(seconds)
    r2 = s.save()
    if keys:
        s.up(*keys)
    frames = (r2.v("frame") - r1.v("frame")) & 255
    da = (r2.v("angle") - r1.v("angle")) & 255
    return (da - 256 if da > 127 else da) / max(frames, 1)


def joystick_game(s):
    # --- titolo ---
    s.wait(1.0)
    r = s.save()
    check("titolo: scritta CIRCULAR DEFENSE nel playfield", text_on_screen(r, gen_text.screen("CIRCULAR", "DEFENSE")))
    m1 = r.v("music")
    s.wait(0.6)
    check("titolo: la musica va avanti", s.save().v("music") != m1)
    check("titolo: controller predefinito = paddle (barra a destra accesa)", r.v("state") & 32 and r[PFSCORE2] == 0xFF)
    grab(s, "titolo")
    s.tap("F1", 0.2)
    s.wait(0.3)
    r = s.save()
    check("Select: si passa al joystick (barra spenta)", not r.v("state") & 32 and r[PFSCORE2] == 0)

    # --- joystick: niente movimento automatico ---
    rate = spin(s, None, 0.6)
    check("joystick: fermo, il difensore non si muove da solo", rate == 0, f"{rate:.2f}")
    rate = spin(s, ["Right"])
    check("joystick: destra = senso orario, 3 unita'/frame", 2.8 <= rate <= 3.2, f"{rate:.2f}")
    rate = spin(s, ["Left"])
    check("joystick: sinistra = senso antiorario, -3 unita'/frame", -3.2 <= rate <= -2.8, f"{rate:.2f}")

    # --- partita ---
    s.tap("space", 0.2)
    s.wait(0.5)
    r = s.save()
    check("fuoco: livello 1, 8 colpi da parare, 6 citta' intere, barra dei livelli a 1",
          r.v("state") & 1 and r.v("level") == 1 and r.v("quota") == 8 and r.v("alive") == 63
          and all_lit(r) == 48 and r[PFSCORE1] == 1, f"pezzetti={all_lit(r)}")
    rate = spin(s, None, 0.6)
    check("in partita il difensore resta fermo se non lo muovi", rate == 0, f"{rate:.2f}")
    grab(s, "partita")

    # --- colpo parato ---
    s.poke({V["angle"]: round(90 * 256 / 360)})          # difensore sopra la citta' 1 (in basso)
    score0 = s.save().score()
    bullet(s, 1, 20)
    heard = sfx_seen(s, 1.0)
    r = s.save()
    check("colpo parato dal difensore: +10, quota 7, nessun pezzetto perso, suono",
          r.score() == score0 + 10 and r.v("quota") == 7 and all_lit(r) == 48 and 2 in heard,
          f"punti {score0}->{r.score()} quota={r.v('quota')} suoni={sorted(heard)}")

    # --- citta' colpita: un pezzetto alla volta, dall'alto ---
    city = 0
    bullet(s, city, 58, {V["angle"]: far_angle(city)})
    heard = sfx_seen(s, 0.6)
    r = s.save()
    check("colpo non parato: la citta' perde solo il pezzetto piu' alto (la torre), suono del crollo",
          lit(r, city) == list(range(1, 8)) and all_lit(r) == 47 and 3 in heard,
          f"rimasti={lit(r, city)} suoni={sorted(heard)}")
    grab(s, "citta_colpita")
    for k in range(7):
        bullet(s, city, 60, {V["angle"]: far_angle(city)})
        s.wait(0.35)
    r = s.save()
    check("8 colpi: la citta' 0 e' distrutta (bit spento, nessun pezzetto)",
          lit(r, city) == [] and not r.v("alive") & 1 and r.alive() == 5, f"vive={r.v('alive'):06b}")
    bullet(s, city, 60, {V["angle"]: far_angle(city)})
    s.wait(0.4)
    r = s.save()
    check("colpo su una citta' gia' distrutta: cade un pezzetto della piu' vicina (citta' 1)",
          len(lit(r, 1)) == 7 and all_lit(r) == 39, f"citta' 1: {lit(r, 1)}")

    # --- fine livello e bonus ---
    pieces = all_lit(s.save())
    s.poke({V["quota"]: 1, V["angle"]: round(270 * 256 / 360)})   # difensore sopra la citta' 4 (in alto)
    score0 = s.save().score()
    bullet(s, 4, 20)
    t0 = time.time()
    while time.time() - t0 < 6 and s.save().v("level") == 1:
        s.wait(0.2)
    s.wait(0.3)
    r = s.save()
    check(f"livello superato: +10 e 5 punti per ognuno dei {pieces} pezzetti rimasti, poi livello 2",
          r.v("level") == 2 and r.score() == score0 + 10 + 5 * pieces and r.v("quota") == LVQUOTA[2]
          and r[PFSCORE1] == 0b11, f"punti {score0}->{r.score()} livello={r.v('level')}")
    s.poke({V["spawnT"]: 0, V["interval"]: 1, V["b0t"]: 255, V["b1t"]: 255})
    s.wait(0.5)
    r = s.save()
    check("livello 2: due colpi in volo insieme", r.v("b0t") != 255 and r.v("b1t") != 255,
          f"passi={r.v('b0t')},{r.v('b1t')}")

    # --- colpi deviati (livello 4) ---
    s.poke({V["level"]: 4, V["interval"]: 20, V["spawnT"]: 0})
    dev = set()
    t0 = time.time()
    while time.time() - t0 < 12 and not dev:
        r = s.save()
        for b in ("b0", "b1"):
            if r.v(b + "t") != 255 and r.v(b + "v") >= 6:
                dev.add(r.v(b + "v"))
        s.poke({V["alive"]: 63})
        s.wait(0.1)
    check("livello 4: alcuni colpi cambiano direzione a meta' strada", dev, f"velocita' deviate={sorted(dev)}")
    r = s.save()
    city = 3                                                       # in alto a sinistra, ancora intera
    v = 6 + 2 * 2 + 0                                              # parte verso la 2, finisce sulla 3
    before = lit(r, 3)
    bullet(s, v, 40, {V["angle"]: far_angle(3)})
    s.wait(0.8)
    r = s.save()
    check("colpo deviato: finisce sulla citta' vicina (dalla 2 alla 3)",
          TCITY[v] == 3 and len(lit(r, 3)) == len(before) - 1, f"citta' 3: {len(before)} -> {len(lit(r, 3))}")

    # --- buio (livello 6) ---
    s.poke({V["level"]: 6, V["interval"]: 250})
    bullet(s, 4, 0, {V["angle"]: far_angle(4), V["level"]: 6})
    hidden, shown = 0, 0
    for _ in range(30):
        r = s.save()
        if r.v("b0t") != 255:
            if r[MISSILE1Y] == 200:
                hidden += 1
            else:
                shown += 1
        s.wait(0.01)
    check("livello 6 (buio): il colpo si vede solo a tratti", hidden > 0 and shown > 0,
          f"visibile {shown}, nascosto {hidden}")

    # --- vittoria ---
    s.poke({V["level"]: 8, V["quota"]: 1, V["angle"]: round(90 * 256 / 360)})
    score0 = s.save().score()
    bullet(s, 1, 20, {V["level"]: 8, V["quota"]: 1})
    t0 = time.time()
    while time.time() - t0 < 8 and not s.save().v("state") & 8:
        s.wait(0.2)
    s.wait(0.5)
    r = s.save()
    check("superato l'8 livello: VITTORIA (+500), scritta nel playfield",
          r.v("state") & 8 and not r.v("state") & 1 and r.score() >= score0 + 510
          and text_on_screen(r, gen_text.screen("VITTORIA")), f"stato={r.v('state'):08b} punti={r.score()}")
    m1 = r.v("music")
    s.wait(0.6)
    check("vittoria: suona la fanfara", s.save().v("music") != m1)
    grab(s, "vittoria")
    s.tap("space", 0.2)
    s.wait(0.5)
    r = s.save()
    check("fuoco dopo la vittoria: si torna al titolo",
          r.v("state") & 15 == 0 and text_on_screen(r, gen_text.screen("CIRCULAR", "DEFENSE")))

    # --- game over ---
    s.tap("space", 0.2)
    s.wait(0.5)
    r = s.save()                                    # (poke riscrive l'ultimo salvataggio)
    check("fuoco dal titolo: nuova partita con le citta' intere", r.v("state") & 1 and all_lit(r) == 48)
    s.poke({V["alive"]: 1})                         # resta solo la citta' 0 (8 pezzetti)
    for k in range(8):
        bullet(s, 0, 60, {V["angle"]: far_angle(0), V["alive"]: 1} if k == 0 else {V["angle"]: far_angle(0)})
        s.wait(0.35)
    heard = sfx_seen(s, 0.4)
    r = s.save()
    check("ultima citta' distrutta: GAME OVER, scritta nel playfield, sirena",
          r.v("state") & 2 and not r.v("state") & 1 and text_on_screen(r, gen_text.screen("GAME", "OVER"))
          and 4 in heard, f"stato={r.v('state'):08b} suoni={sorted(heard)}")
    grab(s, "game_over")
    s.wait(1.0)
    s.tap("space", 0.2)
    s.wait(0.5)
    r = s.save()
    check("fuoco dopo il game over: si torna al titolo", r.v("state") & 15 == 0)

    # --- levette di difficolta' (Stella: F5/F6 sinistra A/B, F7/F8 destra A/B) ---
    s.tap("F5", 0.2)
    s.tap("F7", 0.2)
    s.tap("space", 0.2)
    s.wait(0.4)
    r = s.save()
    check("levetta destra A: il cannone spara piu' spesso (80-15 = 65 frame)", 60 <= r.v("interval") <= 65,
          f"intervallo={r.v('interval')}")
    bullet(s, 1, 0, {V["angle"]: far_angle(1), V["acc"]: 0})
    r1 = s.save()
    s.wait(0.5)
    r2 = s.save()
    fa = (r2.v("frame") - r1.v("frame")) & 255
    sa = (r2.v("b0t") - r1.v("b0t")) / max(fa, 1)
    check("levetta sinistra A: colpi piu' veloci (8/8 invece di 6/8 passi per frame al livello 1)",
          0.9 <= sa <= 1.1, f"{sa:.2f} passi/frame")
    s.tap("F6", 0.2)
    s.tap("F8", 0.2)


def paddle_game(s):
    s.wait(1.0)
    r = s.save()
    check("paddle: controller predefinito", r.v("state") & 32 and r[PFSCORE2] == 0xFF)
    s.hold(["Left"], 2.0)
    s.wait(0.2)
    r = s.save()
    check("paddle tutto a sinistra (0): difensore all'angolo 0", r[PADDLE] == 0 and r.v("angle") == 0,
          f"paddle={r[PADDLE]} angolo={r.v('angle')}")
    s.hold(["Right"], 2.5)
    s.wait(0.2)
    r = s.save()
    check("paddle tutto a destra (77): difensore quasi a fine giro", r[PADDLE] == 77 and r.v("angle") >= 250,
          f"paddle={r[PADDLE]} angolo={r.v('angle')}")
    s.hold(["Left"], 0.5)
    s.wait(0.2)
    r1 = s.save()
    s.wait(0.6)
    r2 = s.save()
    check("paddle fermo: il difensore resta dov'e'", r1.v("angle") == r2.v("angle"),
          f"{r1.v('angle')} -> {r2.v('angle')}")
    s.tap("space", 0.2)                              # pulsante del paddle
    s.wait(0.5)
    r = s.save()
    check("pulsante del paddle: inizia la partita", r.v("state") & 1 and r.v("level") == 1)
    grab(s, "partita_paddle")


def main():
    # Stella riconosce che la ROM legge i paddle: il joystick va forzato
    s = Stella(ROM, "game", ["-lc", "JOYSTICK"])
    try:
        joystick_game(s)
    finally:
        s.close()
    s = Stella(ROM, "paddle", ["-lc", "PADDLES"])
    try:
        paddle_game(s)
    finally:
        s.close()
    fails = [x for x in RESULTS if not x[1]]
    print(f"\nRISULTATO: {len(RESULTS) - len(fails)}/{len(RESULTS)} controlli superati")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
