"""Modello Python del caricamento livelli e del movimento del BAS (per i controlli statici)."""
from collections import deque

OBJECTS = [
    [0b00000000, 0, 0b00000000, 0b00000000, 0b10101010, 0b01111010, 0b00100010, 18],
    [0b01111111, 0, 0b00000000, 0b00000000, 0b10000000, 0b00000000, 0b00101011, 136],
    [0b00000000, 0, 0b00110111, 0b00000000, 0b00000000, 0b00000000, 0b00001011, 18],
    [0b00000000, 0, 0b10101010, 0b01010101, 0b00000000, 0b00000000, 0b00101011, 136],
    [0b11000000, 0, 0b00000011, 0b00001100, 0b00010000, 0b00010000, 0b00101011, 18],
]
PUSH_START = 12

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
    if level >= 5:
        vline(PUSH_START, 8, 10)
    return on


def drop_cells(level, objects=OBJECTS):
    cells = set()
    bits = objects[level - 1][3]
    for i in range(8):
        if bits & (1 << i):
            col = 3 + 7 * (i % 4)
            top = 0 if i < 4 else 6
            cells |= {(col, r) for r in range(top, top + 4)}
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
            if not (t6 < 34 and (pf(t6, t5) or pf(t6, t3))):
                out.append((x - 1, y))
        if x < 145:
            t5 = ((y - 1) & 255) // 8
            t6 = ((x - 9) & 255) // 4
            t3 = ((y - 4) & 255) // 8
            if not (t6 < 34 and (pf(t6, t5) or pf(t6, t3))):
                out.append((x + 1, y))
        return out

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
    return (v & 7) * 8 + 20, (v // 8) * 8 + 8


def sugar_ok(v, on, reach):
    mx, my = sugar_xy(v)
    col, row = (mx - 18) // 4, (my - 1) // 8
    if (col, row) in on or (col + 1, row) in on:
        return False
    return any((mx + dx, my + dy) in reach for dx, dy in SUGAR_HIT)

BALL_HIT = {(dx, dy) for dx in range(-7, -1) for dy in range(-12, 4)}


def ball_ok(bx, by, reach):
    return any((bx + dx, by + dy) in reach for dx, dy in BALL_HIT)
