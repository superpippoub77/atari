"""Test completo della ROM Atari di Snack 'n' Roll, livello per livello.

Uso (serve Stella, xdotool, ImageMagick e xvfb-run):
  xvfb-run -a -s "-screen 0 800x600x24" python3 test_all.py . "../bin/Snack and Roll.bas.bin" /tmp/screenshot

Gioca una partita completa dal livello 1 alla vittoria pilotando i tasti:
raccoglie gli 8 zuccherini camminando lungo il percorso calcolato sul
playfield letto dalla RAM, spara alla bocca, prende il sacchetto. In piu'
controlla appoggi degli oggetti, gocce, luce, tempo, vite, muro
spingibile (livello 5), selezione del livello e game over.
"""
import sys
import time
from collections import deque

sys.path.insert(0, sys.argv[1])
from snr import *  # noqa

ROM = sys.argv[2]
OUT = sys.argv[3]
RESULTS = []

from model import OBJECTS  # noqa
SUGAR = [
    0, 10, 18, 24, 34, 50, 48, 56,
    0, 8, 16, 24, 10, 48, 50, 58,
    31, 8, 9, 24, 1, 56, 48, 61,
    33, 8, 18, 30, 39, 56, 48, 58,
    0, 8, 18, 31, 38, 32, 48, 56,
]


def check(level, name, ok, detail=""):
    RESULTS.append((level, name, bool(ok), detail))
    print(("  ok   " if ok else "  FAIL ") + f"[L{level}] {name}" + (f"  ({detail})" if detail else ""), flush=True)
    return ok


# ---------------------------------------------------------------------
# modello: drop e muro come ostacoli, movimento identico al BAS
# ---------------------------------------------------------------------
def drop_cells(level):
    cells = set()
    bits = OBJECTS[level - 1][3]
    for i in range(8):
        if bits & (1 << i):
            col = 3 + 7 * (i % 4)
            top = 0 if i < 4 else 6
            for rr in range(top, top + 4):
                cells.add((col, rr))
    return cells


class Grid:
    def __init__(self, ram, level):
        self.level = level
        self.cells = {(c, r) for r in range(12) for c in range(32) if ram.pf(c, r)}
        self.cells |= drop_cells(level)
        if level >= 5:
            pc = ram.v("pushCol")
            self.cells |= {(pc, 8), (pc, 9), (pc, 10)}

    def pf(self, c, r):
        if c >= 32:  # come pfread: sconfina nella riga successiva
            c, r = c - 32, r + 1
        return (c, r) in self.cells

    def moves(self, x, y):
        pf = self.pf
        out = []
        # su
        if y > 8:
            t5 = ((x - 10) & 255) // 4
            t6 = ((y - 5) & 255) // 8
            t4 = ((x - 17) & 255) // 4
            t3 = (t5 - 1) & 255
            if not ((t5 < 31 and pf(t5, t6)) or (t4 < 31 and pf(t4, t6)) or (t3 < 31 and pf(t3, t6))):
                out.append((x, y - 1))
        # giu'
        if y < 88:
            t5 = ((x - 10) & 255) // 4
            t6 = (y & 255) // 8
            t4 = ((x - 17) & 255) // 4
            t3 = (t5 - 1) & 255
            if not ((t5 < 31 and pf(t5, t6)) or (t4 < 31 and pf(t4, t6)) or (t3 < 31 and pf(t3, t6))):
                out.append((x, y + 1))
        # sinistra
        if x > 10:
            t5 = ((y - 1) & 255) // 8
            t6 = ((x - 18) & 255) // 4
            t3 = ((y - 4) & 255) // 8
            if not (t6 < 34 and (pf(t6, t5) or pf(t6, t3))):
                out.append((x - 1, y))
        # destra
        if x < 145:
            t5 = ((y - 1) & 255) // 8
            t6 = ((x - 9) & 255) // 4
            t3 = ((y - 4) & 255) // 8
            if not (t6 < 34 and (pf(t6, t5) or pf(t6, t3))):
                out.append((x + 1, y))
        return out

    def path(self, start, goals):
        prev = {start: None}
        q = deque([start])
        while q:
            p = q.popleft()
            if p in goals:
                out = []
                while p is not None:
                    out.append(p)
                    p = prev[p]
                return out[::-1]
            for n in self.moves(*p):
                if n not in prev:
                    prev[n] = p
                    q.append(n)
        return None


def sugar_goals(mx, my):
    hit = {(dx, dy) for dy in (1, 2, 3) for dx in range(-7, -1)} | {(dx, 0) for dx in (-6, -5, -4, -3)}
    return {(mx + dx, my + dy) for dx, dy in hit}


def ball_goals(bx, by):
    return {(x, y) for x in range(bx - 7, bx - 1) for y in range(by - 12, by + 4)}


# ---------------------------------------------------------------------
# azioni sul gioco
# ---------------------------------------------------------------------
def protect(s):
    """Congela le bocche (hitCooldown) e ricarica la barra del tempo."""
    s.poke({V["hitCooldown"]: 250, PFSCORE1: 0xFF})


def walk_to(s, level, goals, max_time=40.0):
    """Muove il biscotto con i tasti lungo il percorso calcolato."""
    t0 = time.time()
    start_level_no = None
    last_protect = 0
    while time.time() - t0 < max_time:
        if time.time() - last_protect > 3.5:
            protect(s)
            last_protect = time.time()
        r = s.save()
        if start_level_no is None:
            start_level_no = r.v("level")
        if r.v("level") != start_level_no:
            return True, r  # il livello e' cambiato (sacchetto preso)
        pos = (r[PLAYER0X], r[PLAYER0Y])
        if pos in goals:
            return True, r
        g = Grid(r, level)
        path = g.path(pos, goals)
        if path is None:
            return False, r
        # punta qualche passo avanti lungo il percorso
        k = min(len(path) - 1, 10)
        tx, ty = path[k]
        keys = []
        if tx > pos[0]:
            keys.append("Right")
        elif tx < pos[0]:
            keys.append("Left")
        if ty > pos[1]:
            keys.append("Down")
        elif ty < pos[1]:
            keys.append("Up")
        steps = max(abs(tx - pos[0]), abs(ty - pos[1]))
        slow = r.flag(6)
        dur = max(0.04, min(steps, 8) / 50.0) * (3.5 if slow else 1.0)
        s.hold(keys, dur)
    return False, s.save()


def start_level(s, level):
    """Dal titolo: Select (F1) per scegliere il livello, Reset (F2) per partire."""
    for _ in range(level - 1):
        s.tap("F1", 0.1)
        s.wait(0.15)
    s.tap("F2", 0.15)
    s.wait(0.8)
    return s.save()


def static_checks(s, r, level):
    rows = r.pf_rows()
    print("\n".join("     " + x for x in rows))
    # 1) appoggi: ogni gruppo di pixel deve toccare soffitto (riga 0),
    #    piano di lavoro (riga 5) o pavimento (riga 10)
    drops = drop_cells(level)
    cells = {(c, rr) for rr in range(11) for c in range(32) if r.pf(c, rr) and (c, rr) not in drops}
    seen, floating = set(), []
    for c in sorted(cells):
        if c in seen:
            continue
        comp, q = set(), [c]
        while q:
            p = q.pop()
            if p in comp or p not in cells:
                continue
            comp.add(p)
            q += [(p[0] + 1, p[1]), (p[0] - 1, p[1]), (p[0], p[1] + 1), (p[0], p[1] - 1)]
        seen |= comp
        if not any(p[1] in (0, 5, 10) for p in comp):
            floating.append(sorted(comp))
    check(level, "nessun oggetto sospeso nel vuoto", not floating, str(floating[:3]))
    # 2) parte alta: ogni pixel in riga 4 ha il piano sotto
    unsupported = [c for c in range(32) if (c, 4) in cells and (c, 5) not in cells]
    check(level, "oggetti alti appoggiati sul piano", not unsupported, str(unsupported))
    # 3) parte bassa: ogni pixel in riga 6 (lampade, cioccolato appeso) ha il piano sopra
    hanging = [c for c in range(32) if (c, 6) in cells and (c, 5) not in cells]
    check(level, "lampade/oggetti bassi appesi al piano", not hanging, str(hanging))
    # 4) gocce: una sola goccia per colonna e appoggio presente
    bits = OBJECTS[level - 1][3]
    bad = []
    for i in range(8):
        if bits & (1 << i):
            col, top = 3 + 7 * (i % 4), (0 if i < 4 else 6)
            n = sum(r.pf(col, rr) for rr in range(top, top + 4))
            if n != 1 or (top == 6 and not r.pf(col, 5)):
                bad.append((col, top, n))
    if bits:
        check(level, "gocce: un solo pixel che scende, appeso", not bad, str(bad))


def sugar_phase(s, level):
    s.poke({V["hitCooldown"]: 250})
    for k in range(8):
        r = s.save()
        v = SUGAR[(level - 1) * 8 + k]
        ex, ey = (v & 7) * 8 + 20, (v // 8) * 8 + 8
        # uno alla volta: posizione ferma su tre letture
        pos = []
        for _ in range(3):
            rr = s.save()
            pos.append((rr[MISSILE1X], rr[MISSILE1Y], rr.v("sugarIndex")))
            s.wait(0.07)
        steady = all(p == (ex, ey, k) for p in pos)
        check(level, f"zuccherino {k}: visibile da solo e fermo in ({ex},{ey})", steady, str(pos))
        col, row = (ex - 18) // 4, (ey - 1) // 8
        check(level, f"zuccherino {k}: non dentro un oggetto", not r.pf(col, row) and not r.pf(col + 1, row),
              f"cella pf ({col},{row})")
        g = Grid(r, level)
        goals = sugar_goals(ex, ey)
        p = g.path((r[PLAYER0X], r[PLAYER0Y]), goals)
        check(level, f"zuccherino {k}: raggiungibile", p is not None)
        if p is None:
            # per proseguire il test lo raccogliamo d'ufficio
            s.poke({V["choco_bits"]: r.v("choco_bits") | (1 << k), V["choco_count"]: k + 1})
            continue
        ok, r = walk_to(s, level, goals)
        s.wait(0.25)
        r = s.save()
        got = (r.v("choco_bits") >> k) & 1
        check(level, f"zuccherino {k}: raccolto camminando", ok and got and r.v("choco_count") == k + 1,
              f"bits={bin(r.v('choco_bits'))} count={r.v('choco_count')}")
        if not got:
            s.poke({V["choco_bits"]: r.v("choco_bits") | (1 << k), V["choco_count"]: k + 1})
        if k == 0:
            check(level, "zuccherino dorato: congela le bocche (_hitCooldown)", r.v("hitCooldown") > 0)
        if k == 1:
            check(level, "zuccherino 1: chiave (_hasKey)", r.v("hasKey") == 1)
    r = s.save()
    check(level, "8 zuccherini, nessuno contato due volte", r.v("choco_count") == 8 and r.v("choco_bits") == 0xFF,
          f"count={r.v('choco_count')}")
    check(level, "dopo l'ultimo non compare piu' nulla", r[MISSILE1Y] == 200)
    check(level, "il sacchetto non appare prima di colpire la bocca", r[BALLY] != 28)


def mouth_phase(s, level):
    r = s.save()
    g = Grid(r, level)
    # cerca una posizione raggiungibile con 30 px liberi a destra sulla stessa riga
    start = (r[PLAYER0X], r[PLAYER0Y])
    best = None
    prev = {start: None}
    q = deque([start])
    while q:
        x, y = q.popleft()
        row = ((y - 3) & 255) // 8
        if x < 100 and all(not g.pf(c, row) and not g.pf(c, ((y - 4) & 255) // 8)
                           for c in range(((x - 9) & 255) // 4, ((x + 30) - 9) // 4 + 1)):
            best = (x, y)
            break
        for n in g.moves(x, y):
            if n not in prev:
                prev[n] = (x, y)
                q.append(n)
    if not check(level, "trovata una linea di tiro libera", best is not None):
        return
    ok, r = walk_to(s, level, {best})
    check(level, f"raggiunta la posizione di tiro {best}", ok, f"p0=({r[PLAYER0X]},{r[PLAYER0Y]})")
    attempts = 0
    for attempts in range(1, 4):
        s.hold(["Right"], 0.06)
        r = s.save()
        x, y = r[PLAYER0X], r[PLAYER0Y]
        score0 = r.score()
        # la bocca (ferma per _hitCooldown) viene messa davanti al biscotto, niente slow motion
        s.poke({V["flags"]: r.v("flags") & ~0xC0, V["mouth0x"]: x + 26, V["mouth0y"]: y,
                V["mouth1x"]: x + 26, V["mouth1y"]: y, V["hitCooldown"]: 200})
        # destra e fuoco premuti insieme, come un giocatore vero
        s.down("Right")
        s.tap("space", 0.12)
        s.up("Right")
        s.wait(0.8)
        r = s.save()
        if r.flag(5) == 0:
            break
    check(level, "cioccolatino colpisce la bocca: +10 (una volta sola) e bocca colpita",
          r.flag(5) == 0 and r.score() == score0 + 10,
          f"flag5={r.flag(5)} score {score0}->{r.score()} tentativi={attempts}")
    check(level, "la bocca colpita torna nel suo angolo", (r.v("mouth0x"), r.v("mouth0y")) == (20, 8) or
          (r.v("mouth1x"), r.v("mouth1y")) == (140, 90))
    s.wait(0.3)
    r = s.save()
    exp_bx = OBJECTS[level - 1][7]
    check(level, f"sacchetto apparso in ({exp_bx},28)", r[BALLY] == 28 and r[BALLX] == exp_bx,
          f"ball=({r[BALLX]},{r[BALLY]})")


def bag_phase(s, level):
    r = s.save()
    goals = ball_goals(r[BALLX], r[BALLY])
    g = Grid(r, level)
    p = g.path((r[PLAYER0X], r[PLAYER0Y]), goals)
    check(level, "sacchetto raggiungibile", p is not None)
    ok, r = walk_to(s, level, goals)
    deadline = time.time() + 6
    while time.time() < deadline and r.v("level") == level:
        # avvicinamento fine finche' non tocca il sacchetto
        s.hold(["Up"], 0.04)
        r = s.save()
    check(level, "toccando il sacchetto si passa al livello successivo", r.v("level") == level + 1,
          f"level={r.v('level')}")
    if level < 5:
        check(level + 1, "partenza dal punto (10,64) con 4 vite e tempo pieno",
              abs(r[PLAYER0X] - 10) <= 8 and abs(r[PLAYER0Y] - 64) <= 8 and r[PFSCORE2] == 0xAA and r[PFSCORE1] == 0xFF,
              f"p0=({r[PLAYER0X]},{r[PLAYER0Y]}) vite={r[PFSCORE2]:08b} tempo={r[PFSCORE1]:08b}")
    return r


def push_phase(s):
    level = 5
    r = s.save()
    pc = r.v("pushCol")
    check(level, "muro spingibile disegnato (colonna 12, righe 8-10)",
          pc == 12 and all(r.pf(12, rr) for rr in (8, 9, 10)), f"pushCol={pc}")
    # biscotto a sinistra del muro, sul pavimento, poi Destra tenuto premuto
    s.poke({PLAYER0X: 4 * pc + 9 - 3, PLAYER0Y: 84, V["hitCooldown"]: 250})
    s.hold(["Right"], 3.0)
    r = s.save()
    pc2 = r.v("pushCol")
    ok_cols = all(r.pf(pc2, rr) for rr in (8, 9, 10)) and not any(r.pf(pc, rr) for rr in (8, 9, 10))
    check(level, "spingendo a destra il muro si sposta", pc2 > pc and ok_cols, f"pushCol {pc}->{pc2}")
    check(level, "spingere non attiva lo slow motion", r.flag(6) == 0)
    s.hold(["Right"], 3.0)
    r = s.save()
    check(level, "il muro si ferma a fine corsia (colonna 16, prima della tazza)", r.v("pushCol") == 16,
          f"pushCol={r.v('pushCol')}")
    s.shot(f"{OUT}/atari_L5_muro_destra.png")
    pc = r.v("pushCol")
    s.poke({PLAYER0X: 4 * pc + 18 + 2, PLAYER0Y: 84, V["hitCooldown"]: 250})
    s.hold(["Left"], 6.0)
    r = s.save()
    check(level, "spingendo a sinistra torna indietro fino alla colonna 8", r.v("pushCol") == 8,
          f"pushCol={r.v('pushCol')}")
    rows = r.pf_rows()
    count = sum(rows[rr][c] == "X" for rr in (8, 9, 10) for c in range(8, 17))
    check(level, "nessun pixel residuo nella corsia (solo il muro)", count == 3, f"pixel={count}")
    s.shot(f"{OUT}/atari_L5_muro_sinistra.png")
    # il cioccolatino non distrugge il muro
    pc = r.v("pushCol")
    s.poke({PLAYER0X: 4 * pc + 18 + 14, PLAYER0Y: 84, V["hitCooldown"]: 250})
    s.hold(["Left"], 0.06)
    s.tap("space", 0.1)
    s.wait(0.8)
    r = s.save()
    check(level, "il cioccolatino non distrugge il muro", all(r.pf(pc, rr) for rr in (8, 9, 10)))
    # il biscotto torna al punto di partenza per il resto del livello
    s.poke({PLAYER0X: 10, PLAYER0Y: 64})


def light_phase(s, level):
    s.poke({V["seconds"]: 31, V["frame"]: 54, V["hitCooldown"]: 250})
    s.wait(0.4)
    r = s.save()
    check(level, "dopo 32 secondi la luce si spegne", r.flag(4) == 0)
    s.shot(f"{OUT}/atari_L{level}_buio.png")
    # sotto un pezzo di piano di lavoro, spara in alto
    g = Grid(r, level)
    start = (r[PLAYER0X], r[PLAYER0Y])
    target = None
    for c in range(2, 30):
        if r.pf(c, 5) and r.pf(c + 1, 5):
            x = 4 * c + 18 - 4
            for y in range(54, 62):
                if g.path(start, {(x, y)}) is not None and not g.pf(((x + 4 - 18) & 255) // 4, 5 + 1):
                    target = (x, y)
                    break
        if target:
            break
    if not check(level, "trovato un punto sotto il piano", target is not None):
        return
    walk_to(s, level, {target})
    for attempts in range(1, 4):
        r = s.save()
        s.poke({V["flags"]: r.v("flags") & ~0xC0})
        # su e fuoco insieme: il cioccolatino parte verso l'alto anche se
        # il biscotto e' gia' appoggiato sotto il piano
        s.down("Up")
        s.tap("space", 0.12)
        s.up("Up")
        s.wait(0.6)
        r = s.save()
        if r.flag(4) == 1:
            break
        print(f"     (tentativo {attempts}: p0=({r[PLAYER0X]},{r[PLAYER0Y]}) dir={r.v('dir'):08b})")
    check(level, "sparando sul piano la luce si riaccende", r.flag(4) == 1)


def life_phase(s, level):
    r = s.save()
    lives = r[PFSCORE2]
    s.poke({PFSCORE1: 0x80, V["seconds"]: 15, V["frame"]: 54, V["hitCooldown"]: 0,
            V["mouth0x"]: 20, V["mouth0y"]: 8, V["mouth1x"]: 140, V["mouth1y"]: 90})
    s.wait(0.5)
    r = s.save()
    check(level, "barra del tempo finita: si perde una vita e il tempo riparte", r[PFSCORE2] == lives >> 2 and
          r[PFSCORE1] == 0xFF and r.v("hitCooldown") > 0, f"vite {lives:08b}->{r[PFSCORE2]:08b}")
    lives = r[PFSCORE2]
    x, y = r[PLAYER0X], r[PLAYER0Y]
    s.poke({V["hitCooldown"]: 0, V["mouth0x"]: x, V["mouth0y"]: y, V["mouth1x"]: x, V["mouth1y"]: y})
    s.wait(0.3)
    r = s.save()
    check(level, "toccando la bocca si perde una vita", r[PFSCORE2] == lives >> 2, f"{lives:08b}->{r[PFSCORE2]:08b}")
    s.poke({PFSCORE2: 0xAA, V["mouth0x"]: 20, V["mouth0y"]: 8, V["mouth1x"]: 140, V["mouth1y"]: 90,
            V["hitCooldown"]: 250})


def play_level(s, level, extra=True):
    r = s.save()
    check(level, "livello caricato", r.v("level") == level and r.flag(0) == 1, f"level={r.v('level')}")
    check(level, "_speed corretto", r.v("speed") == [8, 6, 4, 2, 0][level - 1], f"speed={r.v('speed')}")
    if level == 1:
        check(level, "partenza dal punto (10,64) con 4 vite e tempo pieno",
              (r[PLAYER0X], r[PLAYER0Y]) == (10, 64) and r[PFSCORE2] == 0xAA and r[PFSCORE1] == 0xFF)
    check(level, "luce: spenta solo al livello 5", r.flag(4) == (0 if level == 5 else 1))
    static_checks(s, r, level)
    s.shot(f"{OUT}/atari_L{level}.png")
    s.wait(0.5)
    static_checks(s, s.save(), level)  # anche dopo che le gocce si sono mosse
    if extra:
        if level == 5:
            push_phase(s)
        life_phase(s, level)
    sugar_phase(s, level)
    mouth_phase(s, level)
    if extra and level != 5:
        light_phase(s, level)
    return bag_phase(s, level)


def main():
    # --- partita completa dal livello 1 al 5 ---
    s = Stella(ROM, "test")
    r = s.save()
    check(0, "schermata del titolo", r.flag(0) == 0)
    s.shot(f"{OUT}/atari_titolo.png")
    r = start_level(s, 1)
    for level in range(1, 6):
        r = s.save()
        if r.v("level") != level or r.flag(0) == 0:
            print(f"     (il livello {level} viene avviato dal titolo)")
            s.close()
            s = Stella(ROM, "test")
            start_level(s, level)
        r = play_level(s, level, extra=True)
        if level < 5:
            s.wait(0.3)
        else:
            s.wait(1.0)
            r = s.save()
            check(5, "dopo il livello 5 si torna al titolo (vittoria)", r.flag(0) == 0)
    s.close()

    # --- selezione del livello dal titolo e game over ---
    s = Stella(ROM, "test")
    for level in range(1, 6):
        r = start_level(s, level)
        check(level, f"Select x{level - 1} + Reset parte dal livello {level}", r.v("level") == level)
        s.poke({PFSCORE2: 0x02, V["hitCooldown"]: 0, V["mouth0x"]: r[PLAYER0X], V["mouth0y"]: r[PLAYER0Y],
                V["mouth1x"]: r[PLAYER0X], V["mouth1y"]: r[PLAYER0Y]})
        s.wait(0.5)
        r = s.save()
        check(level, "ultima vita persa: game over e ritorno al titolo", r.flag(0) == 0)
        s.wait(0.3)
    s.close()

    fails = [x for x in RESULTS if not x[2]]
    print(f"\nRISULTATO: {len(RESULTS) - len(fails)}/{len(RESULTS)} controlli superati")
    for f in fails:
        print("  FAIL", f)


main()
