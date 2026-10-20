"""Livello 5: il gioco si puo' bloccare spingendo i muri nel posto sbagliato?

Prova sequenze di spinte a caso (da 1 a 8, come un giocatore che sbaglia) e
dopo ognuna controlla che da li' si possano ancora prendere tutti gli
zuccherini e il sacchetto, con altre spinte.

Uso:  python3 tools/blocchi_muri.py [seme] [sequenze]
"""
import sys, random, time
import os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'tests')); sys.path.insert(0, HERE)
import model, soluzione
from model import Grid, build, wall_cells, single_pushes, can_push
from collections import deque
random.seed(int(sys.argv[1]) if len(sys.argv) > 1 else 1)
lv = 5
walls0 = tuple(model.wall_cols(lv))
static = build(lv) - wall_cells(walls0)
goals = soluzione.level_goals(lv, soluzione.SUGAR[32:40])
allg = set().union(*goals)

def all_reachable(ws, pos, cap=250):
    """da (muri, posizione): ogni obiettivo si raggiunge in qualche stato? (BFS limitata)"""
    need = set(range(len(goals)))
    seen = set(); q = deque([(ws, pos)]); n = 0
    while q and n < cap:
        ws, pos = q.popleft(); n += 1
        cells = Grid(static | wall_cells(ws)).reachable(pos)
        key = (ws, min(cells))
        if key in seen:
            continue
        seen.add(key)
        need -= {i for i in need if goals[i] & cells}
        if not need:
            return True
        for wi, d, k, new in single_pushes(static, ws, cells):
            at = min(can_push(cells, ws[wi], d))
            q.append((tuple(new), (at[0] + 4 * k * d, at[1])))
        del cells
    return None if q else False      # None: limite raggiunto

walks, bad, unk = int(sys.argv[2]) if len(sys.argv) > 2 else 60, 0, 0
t = time.time()
for w in range(walks):
    ws, pos = walls0, (10, 64)
    for step in range(random.randint(1, 8)):
        cells = Grid(static | wall_cells(ws)).reachable(pos)
        opts = single_pushes(static, ws, cells)
        if not opts:
            break
        wi, d, k, new = random.choice(opts)
        at = random.choice(sorted(can_push(cells, ws[wi], d)))
        after = (at[0] + 4 * k * d, at[1])
        if not Grid(static | wall_cells(new)).moves(*after):
            continue
        ws, pos = tuple(new), after
    r = all_reachable(ws, pos)
    if r is False:
        bad += 1
        print("BLOCCATO:", ws, pos, flush=True)
    elif r is None:
        unk += 1
    if w % 10 == 9:
        print(f"{w+1} sequenze, bloccate {bad}, non decise {unk}, {time.time()-t:.0f}s", flush=True)
print(f"FINE: {walks} sequenze, bloccate {bad}, non decise {unk}")
