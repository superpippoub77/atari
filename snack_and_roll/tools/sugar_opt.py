"""Analisi e ottimizzazione della posizione degli zuccherini (data sugar del BAS).

Per ogni livello:
  - percorsi reali (stesso modello di movimento dei test, tests/model.py):
    partenza (10,64) -> zuccherini 0..7 nell'ordine di comparsa -> sacchetto;
  - simulazione Monte Carlo di un giocatore "umano": si ferma un attimo a
    cercare lo zuccherino nuovo, non tiene sempre la levetta, impiega tempo a
    bucare i blocchi, spara alle bocche quando sono allineate (al buio, dopo
    32 secondi, le vede poco); le bocche inseguono come nel BAS (un passo ogni
    _speed frame, al doppio con il sacchetto visibile, lo zuccherino dorato
    le ferma 120 frame, una bocca colpita ricompare dopo 200 frame);
  - misure: tempo, equilibrio dei tratti (nessun tratto troppo corto o troppo
    lungo), copertura dello schema, probabilita' di essere morsi.

Uso:  python3 tools/sugar_opt.py            -> confronto attuale / ottimizzato
      python3 tools/sugar_opt.py --write    -> scrive anche la tabella nel BAS
"""
import os
import random
import re
import statistics
import sys
from collections import deque

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "tests"))

import model  # noqa: E402
from model import Grid, build, destroy_closure, drop_cells, sugar_cell, sugar_xy, wall_cols  # noqa: E402
import sugar_layout  # noqa: E402

BAS = os.path.join(HERE, "..", "Snack and Roll.bas")
START = (10, 64)
ORDER = sugar_layout.ORDER                 # sezioni nell'ordine di comparsa
MOUTH_SPEED = [12, 10, 9, 8, 8, 7]         # BAS: data mouthspeed (frame per passo)
FPS = 50
LIGHT_OFF = 32 * 48                        # frame: la luce si spegne a 32 "secondi"
TIME_BAR = 8 * 16 * 48                     # 8 segmenti da 16 "secondi"


def current_table():
    src = open(BAS, encoding="utf-8").read()
    m = re.search(r"data sugar\n(.*?)\nend", src, re.S)
    nums = [int(x) for x in re.findall(r"\d+", m.group(1))]
    return [nums[i * 8:(i + 1) * 8] for i in range(6)]


def sugar_goals(v):
    mx, my = sugar_xy(v)
    return {(mx + dx, my + dy) for dx, dy in model.SUGAR_HIT}


def ball_goals(bx, by=28):
    return {(mx, my) for mx, my in ((bx + dx, by + dy) for dx, dy in model.BALL_HIT)}


class Level:
    def __init__(self, level):
        self.level = level
        o = model.OBJECTS[level - 1]
        self.base = build(level)
        self.moving = bool(o[3])
        self.drops = drop_cells(level)
        # griglia per camminare: blocchi distruttibili bucati, gocce/presse
        # attraversabili (si aspetta il momento giusto, contato a parte)
        cells = self.base if self.moving else self.base | self.drops
        if level in sugar_layout.FIXED:
            # rompicapo dei muri: per misurare i percorsi i muri si
            # considerano gia' spinti dove serve (le spinte costano tempo a parte)
            cells = cells - model.wall_cells(wall_cols(level))
        final, destroyed, _ = destroy_closure(cells, level, push_col=wall_cols(level) or None)
        self.destroyed = destroyed - self.drops
        self.walk = Grid(final)
        self.bag = o[7]
        _, _, _, self.info = sugar_layout.analyse(level)
        self.fixed = sugar_layout.FIXED.get(level)
        self.push_secs = set()
        if self.fixed:
            # rompicapo: le sezioni con lo zuccherino che si prende solo
            # spingendo un muro restano fisse; le altre devono essere libere
            kinds = sugar_layout.check_fixed(level, self.fixed)
            self.push_secs = {sugar_layout.section_of(v) for v in self.fixed if kinds[v] == "push"}
            for v in range(64):
                try:
                    k = sugar_layout.check_fixed(level, [v])[v]
                except RuntimeError:
                    k = "no"
                self.info[v] = "free" if k == "free" else "no"
        self._paths = {}

    def candidates(self, sec):
        if sec in self.push_secs:
            return [v for v in self.fixed if sugar_layout.section_of(v) == sec]
        return [v for v in range(64) if sugar_layout.section_of(v) == sec and self.info[v] != "no"]

    def path(self, start, v):
        """percorso dal punto start allo zuccherino v (o al sacchetto se v None)."""
        key = (start, v)
        if key not in self._paths:
            goals = ball_goals(self.bag) if v is None else sugar_goals(v)
            self._paths[key] = self.walk.path(start, goals)
        return self._paths[key]

    def route(self, seq):
        """lista di tratti (pixel) start -> s0 -> ... -> s7 -> sacchetto."""
        legs, p = [], START
        for v in list(seq) + [None]:
            pt = self.path(p, v)
            if pt is None:
                return None
            legs.append(pt)
            p = pt[-1]
        return legs

    def shots(self, v):
        """blocchi da bucare per lo zuccherino v (0 se fuori dagli oggetti)."""
        return 1 if sugar_cell(v) in self.destroyed else 0

    def drop_crossings(self, leg):
        """quante volte il tratto attraversa una colonna di gocce/presse."""
        if not self.moving:
            return 0
        cols = {c for c, _ in self.drops}
        n, inside = 0, False
        for x, y in leg:
            c = ((x - 14) & 255) // 4
            now = c in cols and (c, (y - 4) // 8) in self.drops
            if now and not inside:
                n += 1
            inside = now
        return n


def simulate(lv, legs, seq, rng, speed=None):
    """una partita al livello lv lungo i tratti legs; ritorna (frame, morsi)."""
    level = lv.level
    speed = speed or MOUTH_SPEED[level - 1]
    two = level > 3
    mw = 16 if two else 8
    mouths = [[20, 8, 0], [140, 90, 0]] if two else [[20, 8, 0]]
    eff = rng.uniform(0.80, 0.97)           # quanto spesso la levetta e' tenuta
    react = rng.uniform(0.8, 1.2)
    f, bites, tick, freeze, cool = 0, 0, 0, 0, 0
    missile = 0
    # luce: si spegne 32 "secondi" dopo l'ultima accensione (il livello delle
    # presse parte al buio); il giocatore la riaccende sparando al piano
    # dopo un po' (frame di buio U(30, 120))
    dark_until = int(rng.uniform(30, 120)) if level == model.PRESS_LEVEL else 0
    light_off_at = dark_until + LIGHT_OFF if level == model.PRESS_LEVEL else LIGHT_OFF
    for i, leg in enumerate(legs):
        # pausa: cerca lo zuccherino nuovo; buca il blocco; aspetta le gocce
        wait = int(rng.uniform(12, 45) * react)
        if i < len(seq):
            wait += lv.shots(seq[i]) * int(rng.uniform(35, 80))
        wait += lv.drop_crossings(leg) * int(rng.uniform(15, 60))
        if i < len(seq) and sugar_layout.section_of(seq[i]) in lv.push_secs:
            wait += int(rng.uniform(60, 140))       # spinta di un muro (stanze A e B)
        k = 0
        pauses = wait
        while k < len(leg) - 1 or pauses > 0:
            f += 1
            if f == light_off_at:
                dark_until = f + int(rng.uniform(30, 120))
                light_off_at = dark_until + LIGHT_OFF
            dark = f < dark_until
            if pauses > 0:
                pauses -= 1
            elif rng.random() < eff:
                k += 1
            cx, cy = leg[k]
            # bocche
            if freeze:
                freeze -= 1
            else:
                tick += 1
                spd = speed // 2 if i == len(legs) - 1 else speed   # sacchetto visibile
                if tick >= spd:
                    tick = 0
                    for m in mouths:
                        if m[2]:
                            continue
                        m[0] += (m[0] < cx) - (m[0] > cx)
                        m[1] += (m[1] < cy) - (m[1] > cy)
            for j, m in enumerate(mouths):
                if m[2]:
                    m[2] -= 1
                    if not m[2]:
                        m[0], m[1] = ((20, 8), (140, 90))[j]
                    continue
                dx, dy = m[0] - cx, m[1] - cy
                # difesa: spara se la bocca e' allineata e vicina (al buio la vede poco)
                if not missile and (abs(dy) <= 3 or abs(dx) <= 3) and abs(dx) + abs(dy) < 70:
                    p = 0.015 if dark else 0.08
                    if rng.random() < p:
                        missile = 25
                        m[2] = 200
                        continue
                if not cool and cx < m[0] + mw and m[0] < cx + 8 and abs(dy) < 6:
                    bites += 1
                    cool = 90
            if missile:
                missile -= 1
            if cool:
                cool -= 1
        if i == 0:
            freeze = 120                        # zuccherino dorato
    return f, bites


def measure(lv, seq, runs=400, seed=1):
    legs = lv.route(seq)
    if legs is None:
        return None
    lens = [len(x) - 1 for x in legs]
    rng = random.Random(seed)
    times, bitten = [], 0
    for _ in range(runs):
        t, b = simulate(lv, legs, seq, rng)
        times.append(t)
        bitten += b > 0
    pts = [sugar_xy(v) for v in seq]
    spread = statistics.mean(abs(a[0] - b[0]) + abs(a[1] - b[1]) for i, a in enumerate(pts) for b in pts[i + 1:])
    near_spawn = sum(1 for x, y in pts if abs(x - 20) + abs(y - 8) < 30 or (lv.level > 3 and abs(x - 140) + abs(y - 90) < 30))
    return {
        "lens": lens, "total": sum(lens), "cv": statistics.pstdev(lens[:-1]) / statistics.mean(lens[:-1]),
        "short": min(lens[:-1]), "long": max(lens[:-1]),
        "time": statistics.mean(times) / FPS, "p_bite": bitten / runs,
        # (il livello delle presse parte gia' al buio)
        "late": 0.0 if lv.level == model.PRESS_LEVEL else sum(t > LIGHT_OFF for t in times) / runs,
        "inside": sum(lv.shots(v) for v in seq), "spread": spread, "near_spawn": near_spawn,
    }


# difficolta' crescente: probabilita' di essere morsi e tempo medio voluti
TARGET_P = {1: 0.10, 2: 0.15, 3: 0.20, 4: 0.40, 5: 0.45, 6: 0.50}
TARGET_T = {1: 24, 2: 26, 3: 28, 4: 29, 5: 31, 6: 31}     # secondi (luce a ~31 s)


def cost(m, level):
    c = 0.0
    c += 3.0 * m["cv"]                                   # tratti equilibrati
    c += 2.0 * max(0, 40 - m["short"]) / 40              # niente tratti cortissimi
    c += 4.0 * abs(m["p_bite"] - TARGET_P[level])
    c += 1.5 * abs(m["time"] - TARGET_T[level]) / TARGET_T[level]
    c += 1.0 * m["late"]                                  # finire prima del buio
    c += 0.6 * m["near_spawn"]                            # niente zuccherini nell'angolo delle bocche
    c -= 0.004 * m["spread"]                              # sparsi su tutto lo schema
    # dove ci sono blocchi da bucare (tazze, muri di cioccolato) qualche
    # zuccherino ci sta dentro: e' il tema del livello
    c -= (0.25 if level in (2, 3) else 0.08) * min(m["inside"], 3)
    return c


def total_cost(lv, seq, m, others):
    # varieta': stesse posizioni gia' usate negli altri livelli
    same = sum(v in o for o in others for v in seq)
    return cost(m, lv.level) + 0.05 * same


def optimise(lv, start_seq, others=(), iters=700, seed=7):
    """ricerca locale: cambia la cella di uno zuccherino (nella sua sezione)
    oppure scambia l'ordine di comparsa di due zuccherini."""
    rng = random.Random(seed)
    best = list(start_seq)
    bm = measure(lv, best, runs=140)
    bc = total_cost(lv, best, bm, others) if bm else 1e9
    for it in range(iters):
        seq = list(best)
        for _ in range(rng.choice((1, 1, 2))):
            k = rng.randrange(8)
            if rng.random() < 0.35:
                j = rng.randrange(8)
                seq[k], seq[j] = seq[j], seq[k]
            else:
                seq[k] = rng.choice(lv.candidates(sugar_layout.section_of(seq[k])))
        if seq == best:
            continue
        m = measure(lv, seq, runs=140, seed=it)
        if m is None:
            continue
        c = total_cost(lv, seq, m, others)
        if c < bc:
            best, bm, bc = seq, m, c
    return best


def fmt(m):
    return (f"tempo {m['time']:5.1f}s  morso {100 * m['p_bite']:4.1f}%  buio {100 * m['late']:4.1f}%  "
            f"tratti {m['short']:3d}-{m['long']:3d}px (cv {m['cv']:.2f})  bucati {m['inside']}  "
            f"sparsi {m['spread']:5.1f}  angolo {m['near_spawn']}")


def main():
    write = "--write" in sys.argv
    table = current_table()
    new = []
    for level in range(1, 7):
        lv = Level(level)
        cur = table[level - 1]
        mc = measure(lv, cur, runs=2000)
        print(f"\nLivello {level}")
        print("  attuale     ", cur, "\n              ", fmt(mc))
        best = optimise(lv, cur, others=new)
        mb = measure(lv, best, runs=2000)
        if total_cost(lv, best, mb, new) >= total_cost(lv, cur, mc, new):
            best, mb = cur, mc
        print("  ottimizzato ", best, "\n              ", fmt(mb))
        new.append(best)
    print("\ndata sugar")
    for seq in new:
        print("   " + ", ".join(str(v) for v in seq) + ",")
    if write:
        src = open(BAS, encoding="utf-8").read()
        body = "\n".join("   " + ", ".join(str(v) for v in seq) + "," for seq in new)
        src = re.sub(r"(data sugar\n\n).*?(\nend)", lambda m: m.group(1) + body + m.group(2), src, flags=re.S)
        open(BAS, "w", encoding="utf-8").write(src)
        print("scritto in", BAS)


if __name__ == "__main__":
    main()
