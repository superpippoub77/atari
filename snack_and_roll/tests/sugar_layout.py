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
from model import (OBJECTS, Grid, build, destroy_closure, drop_cells, lamp_cells, rows,
                   sugar_cell, sugar_reachable, sugar_xy, ball_ok)

PUSH_LANE = {(c, r) for c in range(8, 17) for r in (8, 9, 10)}


def section_of(v):
    """sezione b0..b7 a cui appartiene la cella v (colonne 2k e 2k+1)."""
    c, r = v % 8, v // 8
    return (c // 2) + (4 if r > 3 else 0)


def analyse(level, objects=OBJECTS):
    base = build(level, objects)
    drops = drop_cells(level, objects)
    push = model.PUSH_START if level >= 5 else None
    # le gocce sono ostacoli che si muovono: non si contano come distruttibili
    final, destroyed, reach = destroy_closure(base | drops, level, push_col=push)
    final |= drops
    reach = Grid(final).reachable()
    destroyed -= drops
    lamps = lamp_cells(level, objects)
    info = {}
    for v in range(64):
        cell = sugar_cell(v)
        if cell in drops or (level >= 5 and cell in PUSH_LANE):
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


# ordine di comparsa: si parte in basso a sinistra (vicino al biscotto) e
# si attraversa lo schermo alternando sotto/sopra
ORDER = [4, 0, 5, 1, 6, 2, 7, 3]


def layout(objects=OBJECTS, verbose=True):
    table = []
    for level in range(1, 6):
        base, destroyed, reach, info = analyse(level, objects)
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
            print(f"\nLivello {level}  (X oggetto, o distruttibile, 0-7 zuccherini in ordine di comparsa)")
            print("   " + "".join(str(c % 10) for c in range(32)))
            for r, line in enumerate(grid):
                print(f"{r:2d} " + "".join(line))
            for i, v in enumerate(seq):
                print(f"   {i}: valore {v:2d} sezione b{section_of(v)} {info[v]:6s} xy={sugar_xy(v)}")
            print("   sacchetto raggiungibile:", ball_ok(objects[level - 1][7], 28, reach))
    return table


if __name__ == "__main__":
    t = layout()
    print("\ndata sugar")
    for i, seq in enumerate(t):
        print("   " + ", ".join(str(v) for v in seq) + ",")
    sys.exit(0)
