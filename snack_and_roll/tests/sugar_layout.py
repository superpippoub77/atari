"""Calcola e verifica la disposizione degli zuccherini (data sugar del BAS).

Regole:
  - ogni zuccherino e' fuori dagli oggetti indistruttibili, oppure dentro un
    oggetto distruttibile (riga in cima di un gruppo) che il giocatore riesce
    davvero a bucare con i cioccolatini;
  - deve essere raggiungibile dal punto di partenza (eventualmente dopo aver
    bucato gli oggetti distruttibili);
  - uno zuccherino per ognuna delle 8 sezioni (b0..b7): distribuiti su tutto
    lo schema, sopra e sotto il piano di lavoro.

Uso:  python3 sugar_layout.py          -> stampa mappe e tabella per il BAS
"""
import sys

import model
from model import (OBJECTS, LEVELS, Grid, build, destroy_closure, drop_cells, lamp_cells, rows, wall_cols,
                   sugar_cell, sugar_reachable, sugar_xy, ball_ok)



def push_lanes(level, base, objects=OBJECTS):
    """Celle in cui un muro spingibile puo' arrivare (righe 8-10 o 2-4)."""
    lane = set()
    for k in wall_cols(level, objects):
        c0, rows_k = k & 127, model.wall_rows(k)
        for step in (-1, 1):
            c = c0
            while 0 <= c <= 31:
                if c != c0 and any((c, r) in base for r in rows_k):
                    break
                lane |= {(c, r) for r in rows_k}
                c += step
    return lane


def section_of(v):
    """sezione b0..b7 a cui appartiene la cella v (colonne 2k e 2k+1)."""
    c, r = v % 8, v // 8
    return (c // 2) + (4 if r > 3 else 0)


def analyse(level, objects=OBJECTS):
    base = build(level, objects)
    drops = drop_cells(level, objects)
    push = wall_cols(level, objects) or None
    lane = push_lanes(level, base, objects)
    # le gocce sono ostacoli che si muovono: non si contano come distruttibili.
    # Le presse si attraversano al momento giusto: non bloccano la strada
    # (ma nessuno zuccherino sta nella loro colonna)
    press = level == model.PRESS_LEVEL
    final, destroyed, reach = destroy_closure(base if press else base | drops, level, push_col=push)
    if not press:
        final |= drops
    reach = Grid(final).reachable()
    destroyed -= drops
    lamps = lamp_cells(level, objects)
    info = {}
    for v in range(64):
        cell = sugar_cell(v)
        if cell in drops or cell in lane:
            kind = "no"          # colonna delle gocce o corsia del muro
        elif cell in lamps:
            kind = "no"          # dentro una lampada no
        elif cell in base:
            kind = "inside" if cell in destroyed else "no"
        else:
            kind = "free"
        if kind != "no" and not sugar_reachable(v, reach):
            kind = "no"
        info[v] = kind
    return base, destroyed, reach, info


def choose(level, info, base):
    """Una cella per sezione. Dove la sezione ha oggetti distruttibili si
    preferisce metterci dentro lo zuccherino, altrimenti una cella libera
    vicino agli oggetti; righe variate per non allinearli."""
    picks = {}
    for sec in range(8):
        cand = [v for v in range(64) if section_of(v) == sec and info[v] != "no"]
        if not cand:
            raise RuntimeError(f"L{level}: sezione b{sec} senza posizioni valide")
        upper = sec < 4
        # riga e colonna preferite cambiano da sezione a sezione e da
        # livello a livello, cosi' gli schemi non si ripetono
        k = (sec * 3 + level) % 4
        pref_row = k if upper else 4 + (3 - k)
        pref_col = (sec % 4) * 2 + ((sec + level) % 2)

        def score(v):
            s = 0
            if info[v] == "inside":
                s -= 10
            s += abs(v // 8 - pref_row)
            s += 0 if v % 8 == pref_col else 1
            # vicino a un oggetto (non in mezzo al vuoto)
            c, r = sugar_cell(v)
            near = any((c + dx, r + dy) in base for dx in (-2, -1, 0, 1, 2) for dy in (-1, 0, 1))
            s -= 1 if near else 0
            return (s, v)
        picks[sec] = min(cand, key=score)
    return picks


# livelli con la disposizione decisa a mano (verificata qui sotto):
# livello 5 = muri mobili. Gli zuccherini delle stanze A (b5) e B (b6)
# si prendono solo spingendo un muro.
FIXED = {5: [33, 9, 43, 11, 37, 13, 47, 15]}


def check_fixed(level, seq, objects=OBJECTS):
    base = build(level, objects)
    lamps = lamp_cells(level, objects)
    reach0, union = model.push_reach(level, objects)
    info = {}
    for v in seq:
        cell = sugar_cell(v)
        if cell in base or cell in lamps:
            raise RuntimeError(f"L{level}: zuccherino {v} dentro un oggetto")
        if cell in push_lanes(level, base, objects):
            raise RuntimeError(f"L{level}: zuccherino {v} dove un muro spinto puo' coprirlo")
        if not sugar_reachable(v, union):
            raise RuntimeError(f"L{level}: zuccherino {v} irraggiungibile anche spingendo i muri")
        info[v] = "free" if sugar_reachable(v, reach0) else "push"
    return info


# ordine di comparsa: si parte in basso a sinistra (vicino al biscotto) e
# si attraversa lo schermo alternando sotto/sopra
ORDER = [4, 0, 5, 1, 6, 2, 7, 3]


def layout(objects=OBJECTS, verbose=True):
    table = []
    for level in range(1, LEVELS + 1):
        base, destroyed, reach, info = analyse(level, objects)
        if level in FIXED:
            seq = FIXED[level]
            info = check_fixed(level, seq, objects)
            assert sorted(section_of(v) for v in seq) == list(range(8)), f"L{level}: una per sezione"
        else:
            picks = choose(level, info, base)
            seq = [picks[sec] for sec in ORDER]
        table.append(seq)
        if verbose:
            grid = [list(r) for r in rows(base)]
            for c, r in destroyed:
                if r < 11 and c < 32:
                    grid[r][c] = "o"     # distruttibile e raggiungibile
            for i, v in enumerate(seq):
                c, r = sugar_cell(v)
                grid[r][c] = str(i)
            print(f"\nLivello {level}  (X oggetto, o distruttibile, 0-7 zuccherini in ordine di comparsa;"
                  " push = solo spingendo un muro)")
            print("   " + "".join(str(c % 10) for c in range(32)))
            for r, line in enumerate(grid):
                print(f"{r:2d} " + "".join(line))
            for i, v in enumerate(seq):
                print(f"   {i}: valore {v:2d} sezione b{section_of(v)} {info[v]:6s} xy={sugar_xy(v)}")
            if wall_cols(level, objects):
                reach = model.push_reach(level, objects)[1]
            print("   sacchetto raggiungibile:", ball_ok(objects[level - 1][7], 28, reach))
    return table


if __name__ == "__main__":
    t = layout()
    print("\ndata sugar")
    for i, seq in enumerate(t):
        print("   " + ", ".join(str(v) for v in seq) + ",")
    sys.exit(0)
