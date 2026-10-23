"""Modello Python del caricamento livelli e del movimento del BAS (per i controlli statici)."""
from collections import deque

OBJECTS = [
    [0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b10101010, 0b01111010, 0b00100010, 18],
    [0b01111111, 0b00000000, 0b00000000, 0b00000000, 0b10000000, 0b00000000, 0b00101011, 136],
    [0b00000000, 0b00000000, 0b00110111, 0b00000000, 0b00000000, 0b00000000, 0b00001011, 18],
    [0b00000000, 0b00000000, 0b00000000, 0b11111111, 0b00000000, 0b00000000, 0b00101011, 136],
    [0b00000000, 0b11101100, 0b00000000, 0b00000000, 0b11101100, 0b00000000, 0b01111110, 136],
    [0b00000000, 0b00000000, 0b00000000, 0b11111111, 0b00000000, 0b00000000, 0b00101011, 136],
]
# livello delle PRESSE (l'ultimo): la colonna 3 di objects sono presse, non gocce
PRESS_LEVEL = 6
LEVELS = len(OBJECTS)

# collisione biscotto/zuccherino misurata in Stella (dx, dy rispetto allo zuccherino)
SUGAR_HIT = {(dx, dy) for dy in (1, 2, 3) for dx in range(-7, -1)} | {(dx, 0) for dx in (-6, -5, -4, -3)}


def build(level, objects=OBJECTS):
    o = objects[level - 1]
    on = set()

    def hline(c0, r, c1, val=True):
        for c in range(c0, c1 + 1):
            (on.add if val else on.discard)((c, r))

    def vline(c, r0, r1, val=True):
        for r in range(r0, r1 + 1):
            (on.add if val else on.discard)((c, r))

    bits = o[6]
    c0, c1 = 0, 7
    while True:
        if bits & 1:
            hline(c0, 5, c1)
        bits >>= 1
        c0 += 4
        c1 = c0 + 4
        if c0 >= 28:
            break
    for i in range(8):
        b = 1 << i
        s = 3 + 7 * (i % 4)
        upper = i < 4
        up, down = (0, 2) if upper else (6, 8)
        if o[0] & b:
            for r in range(down, down + 3):
                hline(s, r, s + 4)
            on.discard((s + 4, down + 2))
            if upper:
                hline(s, 5, s + 4)
        if o[2] & b:
            vline(s, down, down + 2)
            vline(s + 4, down - 2, down)
            if upper:
                hline(s, 5, s + 4)
            else:
                on.add((s + 4, 5))
        if o[3] & b and not upper:
            on.add((s, 5))
        if o[4] & b:
            hline(s, up, s + 2)
            on.add((s + 1, up + 1))
            if not upper:
                hline(s, 5, s + 2)
        if o[5] & b:
            hline(s, down + 1, s + 2)
            on.add((s, down + 2))
            on.add((s + 2, down + 2))
            on.add((s + 4, down + 2))
            if upper:
                hline(s, 5, s + 4)
    on |= wall_cells(wall_cols(level, objects))
    return on


def wall_cols(level, objects=OBJECTS):
    """Muri spingibili: colonna 1 di objects, nell'ordine del BAS.
    Bit 0-3: muri sul piano (righe 2-4) nelle colonne 4, 11, 18, 25,
    indicati come colonna + 128; bit 4-7: muri sul pavimento (righe 8-10)."""
    bits = objects[level - 1][1]
    up = [(3 + 7 * k + 1) | 128 for k in range(4) if bits & (1 << k)]
    down = [3 + 7 * k + 1 for k in range(4) if bits & (16 << k)]
    return (up + down)[:5]


def wall_rows(key):
    """righe occupate dal muro (colonna, + 128 se sta sul piano)."""
    return (2, 3, 4) if key & 128 else (8, 9, 10)


def wall_cells(keys):
    return {(k & 127, r) for k in keys for r in wall_rows(k)}


def wall_y(key):
    """y del biscotto per spingere il muro (tutto dentro le righe del muro)."""
    return 36 if key & 128 else 84


def drop_cells(level, objects=OBJECTS):
    """celle delle gocce (5 righe, fino al piano o al pavimento) o delle presse a T (livello PRESS_LEVEL:
    perno di 5 righe e testa larga 3 colonne che puo' stare in ognuna)."""
    cells = set()
    bits = objects[level - 1][3]
    press = level == PRESS_LEVEL
    for i in range(8):
        if bits & (1 << i):
            col = 3 + 7 * (i % 4)
            top = 0 if i < 4 else 6
            cols = (col - 1, col, col + 1) if press else (col,)
            cells |= {(c, r) for c in cols for r in range(top, top + 5)}
    return cells


def rows(on):
    return ["".join("X" if (c, r) in on else "." for c in range(32)) for r in range(11)]


class Grid:
    def __init__(self, cells):
        self.cells = set(cells)

    def pf(self, c, r):
        if c >= 32:
            c, r = c - 32, r + 1
        return (c, r) in self.cells

    def moves(self, x, y):
        pf = self.pf
        out = []
        if y > 8:
            t5 = ((x - 10) & 255) // 4
            t6 = ((y - 5) & 255) // 8
            t4 = ((x - 17) & 255) // 4
            t3 = (t5 - 1) & 255
            if not ((t5 < 31 and pf(t5, t6)) or (t4 < 31 and pf(t4, t6)) or (t3 < 31 and pf(t3, t6))):
                out.append((x, y - 1))
        if y < 88:
            t5 = ((x - 10) & 255) // 4
            t6 = (y & 255) // 8
            t4 = ((x - 17) & 255) // 4
            t3 = (t5 - 1) & 255
            if not ((t5 < 31 and pf(t5, t6)) or (t4 < 31 and pf(t4, t6)) or (t3 < 31 and pf(t3, t6))):
                out.append((x, y + 1))
        if x > 10:
            t5 = ((y - 1) & 255) // 8
            t6 = ((x - 18) & 255) // 4
            t3 = ((y - 4) & 255) // 8
            if not (t6 < 32 and (pf(t6, t5) or pf(t6, t3))):
                out.append((x - 1, y))
        if x < 145:
            t5 = ((y - 1) & 255) // 8
            t6 = ((x - 9) & 255) // 4
            t3 = ((y - 4) & 255) // 8
            if not (t6 < 32 and (pf(t6, t5) or pf(t6, t3))):
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

    def reachable(self, start=(10, 64)):
        seen = {start}
        q = deque([start])
        while q:
            p = q.popleft()
            for n in self.moves(*p):
                if n not in seen:
                    seen.add(n)
                    q.append(n)
        return seen


def sugar_xy(v):
    """Posizione dello zuccherino come nel BAS: colonne del playfield
    1,5,9,...,29; righe 0-3 della tabella = righe 0-3 del playfield (sopra),
    righe 4-7 = righe 6-9 (sotto). Lo zuccherino sta al centro della riga."""
    r = v // 8
    y = r * 8 + 4 + (16 if r > 3 else 0)
    return (v & 7) * 16 + 22, y


def sugar_cell(v):
    mx, my = sugar_xy(v)
    return (mx - 18) // 4, (my - 1) // 8


def sugar_reachable(v, reach):
    mx, my = sugar_xy(v)
    return any((mx + dx, my + dy) in reach for dx, dy in SUGAR_HIT)


# --- cioccolatino (missile0) e oggetti distruttibili ---------------------
DESTRUCTIBLE_ROWS = (0, 2, 6, 8)   # BAS: solo la riga in cima di ogni gruppo


def missile_hit(grid, px, py, d, level=1, push_col=None):
    """Simula il volo del cioccolatino come nel BAS. Ritorna la cella
    distrutta, 'light' se colpisce il piano, oppure None."""
    if d == "up":
        mx, my = px + 4, py - 5
    elif d == "down":
        mx, my = px + 4, py - 1
    elif d == "left":
        mx, my = px + 2, py - 3
    else:
        mx, my = px + 6, py - 3
    for _ in range(100):
        if d == "up":
            my -= 2
            t5, t6 = ((mx - 18) & 255) // 4, ((my - 1) & 255) // 8
        elif d == "down":
            my += 2
            t5, t6 = ((mx - 18) & 255) // 4, (my & 255) // 8
        elif d == "left":
            mx -= 2
            t5, t6 = ((mx - 18) & 255) // 4, ((my - 1) & 255) // 8
        else:
            mx += 2
            t5, t6 = ((mx - 18) & 255) // 4, ((my - 1) & 255) // 8
        mx &= 255
        my &= 255
        if my < 2 or my > 88 or mx > 145 or mx < 2:
            return None
        if t5 > 31:      # fuori dal playfield (a sinistra): nessun urto
            continue
        hit = grid.pf(t5, t6)
        if t6 == 5 and hit:
            return "light"
        if not hit:
            continue
        if push_col is not None:
            keys = push_col if isinstance(push_col, (list, set, tuple)) else [push_col]
            # BAS: righe 0-4 -> colonna + 128, righe 6-10 -> colonna
            if (t6 < 5 and (t5 | 128) in keys) or (t6 > 5 and t5 in keys):
                return None
        if t6 in DESTRUCTIBLE_ROWS:
            return (t5, t6)
        return None
    return None


def destroy_closure(cells, level=1, start=(10, 64), push_col=None):
    """Tutti i pixel che il giocatore riesce a distruggere sparando
    (ripetendo finche' nuovi buchi aprono nuovi passaggi)."""
    cells = set(cells)
    destroyed = set()
    while True:
        g = Grid(cells)
        reach = g.reachable(start)
        new = set()
        for (x, y) in reach:
            for d in ("up", "down", "left", "right"):
                h = missile_hit(g, x, y, d, level, push_col)
                if isinstance(h, tuple) and h in cells:
                    new.add(h)
        if not new:
            return cells, destroyed, reach
        cells -= new
        destroyed |= new

BALL_HIT = {(dx, dy) for dx in range(-7, -1) for dy in range(-12, 4)}


def ball_ok(bx, by, reach):
    return any((bx + dx, by + dy) in reach for dx, dy in BALL_HIT)


def lamp_cells(level, objects=OBJECTS):
    cells = set()
    bits = objects[level - 1][4]
    for i in range(8):
        if bits & (1 << i):
            s = 3 + 7 * (i % 4)
            up = 0 if i < 4 else 6
            cells |= {(s, up), (s + 1, up), (s + 2, up), (s + 1, up + 1)}
    return cells


# --- muri spingibili: zone raggiungibili spingendo un muro ----------------
def can_push(cells_reach, key, d):
    """Il biscotto, in una posizione raggiungibile, spinge il muro key nella
    direzione d (1 destra, -1 sinistra) come nel BAS: parte bassa del
    biscotto nelle righe del muro (8-10, o 2-4 sul piano) e colonna davanti
    = muro. Per seguire il muro oltre la sua vecchia colonna il biscotto deve
    stare tutto dentro le righe del muro (sopra puo' esserci una lampada)."""
    col = key & 127
    if key & 128:
        rows_ok = lambda y: (y - 4) // 8 >= 2 and (y - 1) // 8 <= 4
    else:
        rows_ok = lambda y: (y - 4) // 8 >= 8
    if d == 1:
        return {(x, y) for x, y in cells_reach if rows_ok(y) and ((x - 9) & 255) // 4 == col}
    return {(x, y) for x, y in cells_reach if rows_ok(y) and ((x - 18) & 255) // 4 == col and x > 10}


def lane_ok(key, dest):
    """I muri sul piano (key + 128) scorrono solo nella corsia della loro
    sezione: colonne s..s+4 (s = 3, 10, 17, 24; il muro parte in s+1). Tra due
    corsie restano almeno 2 colonne libere: due muri alti non si toccano mai e
    non si incastrano. I muri sul pavimento vanno ovunque nello schermo."""
    col = key & 127
    if not key & 128:
        return 0 <= dest <= 31
    return 3 <= dest <= 31 and (dest - 3) // 7 == (col - 3) // 7 and (dest - 3) % 7 <= 4


def single_pushes(static, walls_now, reach, max_cols=8):
    """Tutti gli stati raggiungibili con UNA spinta di un muro (di 1..max_cols
    colonne). static = celle senza i muri. Ritorna [(muro, d, n, muri_nuovi)]."""
    out = []
    for i, k in enumerate(walls_now):
        for d in (1, -1):
            if not can_push(reach, k, d):
                continue
            others = wall_cells(w for j, w in enumerate(walls_now) if j != i)
            for n in range(1, max_cols + 1):
                dest = (k & 127) + d * n
                if not lane_ok(k, dest) or any((dest, rr) in static or (dest, rr) in others for rr in wall_rows(k)):
                    break
                new = list(walls_now)
                new[i] = dest | (k & 128)
                out.append((i, d, n, tuple(new)))
    return out


def push_states(static, walls0, start, max_states=6000, goals=None):
    """Tutti gli stati raggiungibili spingendo i muri, una spinta dopo l'altra
    (spingendo n colonne il biscotto segue il muro). Ritorna
    {(muri, zona): (precedente, (muro, d, n, muri_nuovi, punto di spinta))}
    e le zone {zona: celle raggiungibili}; zona = (muri, cella minima).
    Con goals si ferma alla prima zona che ne contiene uno (la piu' vicina)."""
    zones = {}

    def zone(ws, pos):
        for z, cells in zones.items():
            if z[0] == ws and pos in cells:
                return z
        cells = frozenset(Grid(static | wall_cells(ws)).reachable(pos))
        z = (ws, min(cells))
        zones[z] = cells
        return z

    z0 = zone(tuple(walls0), start)
    prev = {z0: None}
    if goals is not None and zones[z0] & goals:
        return prev, zones, z0
    q = deque([z0])
    while q and len(prev) < max_states:
        z = q.popleft()
        ws, cells = z[0], zones[z]
        for wi, d, n, new in single_pushes(static, ws, cells):
            at = min(can_push(cells, ws[wi], d))
            after = (at[0] + 4 * n * d, at[1])
            if not Grid(static | wall_cells(new)).moves(*after):
                continue
            z2 = zone(tuple(new), after)
            if z2 not in prev:
                prev[z2] = (z, (wi, d, n, tuple(new), at))
                if goals is not None and zones[z2] & goals:
                    return prev, zones, z2
                q.append(z2)
    return prev, zones, None


def plan_pushes(static, walls0, start, goals, max_states=6000):
    """Spinte (in ordine) che portano a una zona da cui si raggiungono i goals:
    [(muro, d, n, muri_nuovi, punto di spinta)], [] se non serve, None se non
    si puo'."""
    prev, zones, best = push_states(static, walls0, start, max_states, goals)
    if best is None:
        return None
    out = []
    while prev[best]:
        best, act = prev[best]
        out.append(act)
    return out[::-1]


def push_reach(level, objects=OBJECTS, extra=(), max_states=300):
    """Raggiungibile senza spingere e spingendo i muri (anche piu' volte).
    I primi 300 stati (le spinte piu' vicine) bastano: con tutti (migliaia)
    il risultato e' lo stesso, ma servono minuti e gigabyte di memoria."""
    walls_now = tuple(wall_cols(level, objects))
    cells = build(level, objects) | drop_cells(level, objects) | set(extra)
    static = cells - wall_cells(walls_now)
    reach0 = Grid(cells).reachable()
    if not walls_now:
        return reach0, set(reach0)
    prev, zones, _ = push_states(static, walls_now, (10, 64), max_states)
    union = set()
    for z in prev:
        union |= zones[z]
    return reach0, union
