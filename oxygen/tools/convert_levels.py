"""Converte i livelli JSON di OXYGEN (Phaser) nelle stanze della cartuccia Atari 2600.

Ogni livello e' un mondo 1280x720 diviso in 4 stanze da 640x360 (una per
schermo, 2x2). Ogni stanza diventa un playfield di 32x11 celle (una cella =
20x32,7 pixel del mondo originale) descritto da un elenco di pezzi, che la
cartuccia disegna all'ingresso nella stanza:

  1 riga, c0, c1            muro orizzontale
  2 col, r0, r1             muro verticale
  3 c0, r0, c1, r1, info    base (rettangolo con le pareti e le porte)
        info: bit 0-3 porte sopra/sotto/sinistra/destra, bit 4-5 tipo
        (0 sicura, 1 standard, 2 militare), bit 6 base finale,
        bit 7 base di partenza
  4 tipo, x, y              nemico (tipo: 0 guardia, 1 cecchino, 2 drone, 3 pesante)
  5 n, x, y                 chiave n (0 o 1)
  0                         fine della stanza

Le basi stanno sempre all'inizio dell'elenco (la cartuccia le scorre per
sapere se il giocatore e' dentro una base). x e y sono coordinate di
batari Basic (player0x/player0y).

Controlla anche che, con il modello di movimento (giocatore largo 2 celle e
alto 1), dalla base di partenza si raggiungano tutte le basi, le chiavi e
l'interruttore della base finale (a cancello aperto).

Uso:  python3 convert_levels.py            -> scrive ../rooms.asm e stampa le mappe
"""
import glob
import json
import os
import sys
from collections import deque

HERE = os.path.dirname(os.path.abspath(__file__))
LEVELS = sorted(glob.glob(os.path.join(HERE, "..", "levels", "level*.json")))
OUT = os.path.join(HERE, "..", "rooms.asm")

RW, RH = 640, 360          # stanza nel mondo originale
COLS, ROWS = 32, 11
CW, CH = RW / COLS, RH / ROWS
ENEMY = {"guard": 0, "sniper": 1, "drone": 2, "heavy": 3}
BTYPE = {"safe": 0, "standard": 1, "military": 2}
MIN_W, MIN_H = 8, 5        # base minima in celle (pareti comprese)
MAX_ENEMIES = 2            # nemici per stanza (un solo sprite, a frame alterni)


def cell_x(c):
    """player0x per uno sprite centrato sulla cella c."""
    return 4 * c + 15


def cell_y(r):
    """player0y (riga in basso dello sprite) per la riga r."""
    return 8 * r + 8


def span(a0, a1, size, n):
    """celle coperte dal segmento [a0, a1) (muri sottili: la cella centrale)."""
    if a1 - a0 < size * 1.5:
        c = int(((a0 + a1) / 2) // size)
        return max(0, min(n - 1, c)), max(0, min(n - 1, c))
    c0 = int(round(a0 / size))
    c1 = int(round(a1 / size)) - 1
    return max(0, min(n - 1, c0)), max(0, min(n - 1, max(c0, c1)))


class Room:
    def __init__(self, rx, ry):
        self.rx, self.ry = rx, ry
        self.walls = []        # (kind, a, b, c)
        self.bases = []        # dict
        self.enemies = []      # (type, x, y)
        self.keys = []         # (n, x, y)
        self.dropped = 0

    def cells(self, gate_closed=False):
        on = set()
        # bordi esterni del mondo
        if self.rx == 0:
            on |= {(0, r) for r in range(ROWS)}
        if self.rx == 1:
            on |= {(COLS - 1, r) for r in range(ROWS)}
        if self.ry == 0:
            on |= {(c, 0) for c in range(COLS)}
        if self.ry == 1:
            on |= {(c, ROWS - 1) for c in range(COLS)}
        for kind, a, b, c in self.walls:
            if kind == 1:
                on |= {(x, a) for x in range(b, c + 1)}
            else:
                on |= {(a, y) for y in range(b, c + 1)}
        for bs in self.bases:
            on -= base_inside(bs)
            on |= base_walls(bs, gate_closed and bs["final"])
        return on

    def bytes(self):
        out = []
        for bs in self.bases:
            info = bs["doors"] | (BTYPE[bs["type"]] << 4) | (64 if bs["final"] else 0) | (128 if bs["start"] else 0)
            out += [3, bs["c0"], bs["r0"], bs["c1"], bs["r1"], info]
        for kind, a, b, c in self.walls:
            out += [kind, a, b, c]
        for t, x, y in self.enemies:
            out += [4, t, x, y]
        for n, x, y in self.keys:
            out += [5, n, x, y]
        return out + [0]


def door_gaps(bs):
    """celle delle porte: sopra/sotto 3 colonne al centro, ai lati 2 righe."""
    c0, r0, c1, r1, d = bs["c0"], bs["r0"], bs["c1"], bs["r1"], bs["doors"]
    mc = (c0 + c1) // 2
    mr = (r0 + r1) // 2
    rows = [mr, mr + 1]
    gaps = []
    if d & 1:
        gaps.append({(c, r0) for c in (mc - 1, mc, mc + 1)})
    if d & 2:
        gaps.append({(c, r1) for c in (mc - 1, mc, mc + 1)})
    if d & 4:
        gaps.append({(c0, r) for r in rows})
    if d & 8:
        gaps.append({(c1, r) for r in rows})
    return gaps


def base_walls(bs, closed):
    c0, r0, c1, r1 = bs["c0"], bs["r0"], bs["c1"], bs["r1"]
    w = {(c, r0) for c in range(c0, c1 + 1)} | {(c, r1) for c in range(c0, c1 + 1)}
    w |= {(c0, r) for r in range(r0, r1 + 1)} | {(c1, r) for r in range(r0, r1 + 1)}
    if not closed:
        for g in door_gaps(bs):
            w -= g
    return w


def base_inside(bs):
    return {(c, r) for c in range(bs["c0"] + 1, bs["c1"]) for r in range(bs["r0"] + 1, bs["r1"])}


def convert(path):
    d = json.load(open(path))
    rooms = {(rx, ry): Room(rx, ry) for ry in (0, 1) for rx in (0, 1)}
    # muri: divisi tra le stanze che attraversano
    for o in d.get("obstacles", []):
        if o.get("type") != "wall":
            continue
        x0, y0, x1, y1 = o["x"], o["y"], o["x"] + o["width"], o["y"] + o["height"]
        for (rx, ry), room in rooms.items():
            ax0, ay0 = max(x0, rx * RW), max(y0, ry * RH)
            ax1, ay1 = min(x1, rx * RW + RW), min(y1, ry * RH + RH)
            if ax1 <= ax0 or ay1 <= ay0:
                continue
            lx0, lx1, ly0, ly1 = ax0 - rx * RW, ax1 - rx * RW, ay0 - ry * RH, ay1 - ry * RH
            ca, cb = span(lx0, lx1, CW, COLS)
            ra, rb = span(ly0, ly1, CH, ROWS)
            if o["width"] >= o["height"]:
                for r in range(ra, rb + 1):
                    room.walls.append((1, r, ca, cb))
            else:
                for c in range(ca, cb + 1):
                    room.walls.append((2, c, ra, rb))
    # basi: tutte nella stanza del loro centro, almeno MIN_W x MIN_H celle
    doorbits = {"top": 1, "bottom": 2, "left": 4, "right": 8}
    for i, b in enumerate(d["bases"]):
        cx, cy = b["x"] + b["w"] / 2, b["y"] + b["h"] / 2
        rx, ry = int(cx // RW), int(cy // RH)
        lcx, lcy = (cx - rx * RW) / CW, (cy - ry * RH) / CH
        w = max(MIN_W, int(round(b["w"] / CW)))
        h = max(MIN_H, int(round(b["h"] / CH)))
        c0 = int(round(lcx - w / 2))
        r0 = int(round(lcy - h / 2))
        doors = sum(doorbits[x] for x in b.get("doors", ["bottom"]))
        # davanti a ogni porta resta almeno una cella libera prima del bordo
        lo_c = 1 + (1 if doors & 4 else 0)
        hi_c = COLS - 1 - w - (1 if doors & 8 else 0)
        lo_r = 1 + (1 if doors & 1 else 0)
        hi_r = ROWS - 1 - h - (1 if doors & 2 else 0)
        c0 = max(lo_c, min(hi_c, c0))
        r0 = max(lo_r, min(hi_r, r0))
        bs = {"id": b["id"], "c0": c0, "r0": r0, "c1": c0 + w - 1, "r1": r0 + h - 1,
              "type": b["type"], "final": bool(b.get("final")), "start": i == 0,
              "doors": doors}
        rooms[(rx, ry)].bases.append(bs)
    # nemici
    for e in d.get("enemies", []):
        rx, ry = int(e["x"] // RW), int(e["y"] // RH)
        room = rooms[(rx, ry)]
        c, r = int((e["x"] - rx * RW) / CW), int((e["y"] - ry * RH) / CH)
        if len(room.enemies) >= MAX_ENEMIES:
            room.dropped += 1
            continue
        room.enemies.append([ENEMY.get(e.get("type"), 0), c, r])
    # chiavi
    for n, k in enumerate(d.get("collectibles", [])[:2]):
        rx, ry = int(k["x"] // RW), int(k["y"] // RH)
        c, r = int((k["x"] - rx * RW) / CW), int((k["y"] - ry * RH) / CH)
        rooms[(rx, ry)].keys.append([n, c, r])
    open_closed_bases(rooms)
    clip_walls(rooms)
    fix_positions(rooms)
    return d, rooms


def clip_walls(rooms):
    """la cartuccia disegna i muri dopo le basi: un muro non deve entrare in
    una base (ne' coprirne le pareti e le porte), quindi si spezza."""
    for room in rooms.values():
        block = set()
        for b in room.bases:
            block |= {(c, r) for c in range(b["c0"], b["c1"] + 1) for r in range(b["r0"], b["r1"] + 1)}
        out = []
        for kind, a, b0, b1 in room.walls:
            run = []
            for t in range(b0, b1 + 1):
                cell = (t, a) if kind == 1 else (a, t)
                if cell in block:
                    if run:
                        out.append((kind, a, run[0], run[-1]))
                    run = []
                else:
                    run.append(t)
            if run:
                out.append((kind, a, run[0], run[-1]))
        # niente doppioni
        room.walls = sorted(set(out))


def free_cells(room, gate_closed=False):
    on = room.cells(gate_closed)
    return {(c, r) for c in range(COLS) for r in range(ROWS) if (c, r) not in on}


def stand(free, c, r):
    """il giocatore (2 celle x 1) puo' stare con la cella sinistra in (c, r)."""
    return (c, r) in free and (c + 1, r) in free


def fix_positions(rooms):
    """nemici e chiavi su celle libere, fuori dalle basi; poi in coordinate di gioco."""
    for room in rooms.values():
        free = free_cells(room)
        inside = set().union(*[base_inside(b) for b in room.bases]) if room.bases else set()
        for lst in (room.enemies, room.keys):
            for item in lst:
                c, r = item[1], item[2]
                best = min(((abs(cc - c) + abs(rr - r), cc, rr) for cc in range(1, COLS - 2) for rr in range(1, ROWS - 1)
                            if stand(free, cc, rr) and (cc, rr) not in inside and (cc + 1, rr) not in inside),
                           default=None)
                if best is None:
                    raise RuntimeError("nessuna cella libera")
                item[1], item[2] = best[1], best[2]


def reach_world(rooms, start):
    """BFS sulle 4 stanze (cella sinistra del giocatore), passando dai bordi."""
    free = {k: free_cells(r) for k, r in rooms.items()}
    seen = {start}
    q = deque([start])
    while q:
        (rx, ry), c, r = q.popleft()
        f = free[(rx, ry)]
        nxt = [((rx, ry), c + dc, r + dr) for dc, dr in ((1, 0), (-1, 0), (0, 1), (0, -1))]
        # passaggi tra le stanze
        if c >= COLS - 2 and rx == 0:
            nxt.append(((1, ry), 0, r))
        if c <= 0 and rx == 1:
            nxt.append(((0, ry), COLS - 2, r))
        if r >= ROWS - 1 and ry == 0:
            nxt.append(((rx, 1), c, 0))
        if r <= 0 and ry == 1:
            nxt.append(((rx, 0), c, ROWS - 1))
        for k, cc, rr in nxt:
            if 0 <= cc < COLS - 1 and 0 <= rr < ROWS and stand(free[k], cc, rr) and (k, cc, rr) not in seen:
                seen.add((k, cc, rr))
                q.append((k, cc, rr))
    return seen


def open_closed_bases(rooms):
    """una base irraggiungibile riceve una porta verso il centro della stanza."""
    for _ in range(8):
        start_room = next(k for k, r in rooms.items() for b in r.bases if b["start"])
        sb = next(b for b in rooms[start_room].bases if b["start"])
        seen = reach_world(rooms, (start_room, (sb["c0"] + sb["c1"]) // 2 - 1, (sb["r0"] + sb["r1"]) // 2))
        changed = False
        for k, room in rooms.items():
            for b in room.bases:
                if any((k, c, r) in seen for c, r in base_inside(b)):
                    continue
                cx, cy = (b["c0"] + b["c1"]) / 2, (b["r0"] + b["r1"]) / 2
                order = ([8, 4] if cx < COLS / 2 else [4, 8]) + ([2, 1] if cy < ROWS / 2 else [1, 2])
                if abs(cy - ROWS / 2) * 3 > abs(cx - COLS / 2):
                    order = order[2:] + order[:2]
                for bit in order:
                    if not b["doors"] & bit:
                        b["doors"] |= bit
                        changed = True
                        break
        if not changed:
            return


def check(d, rooms, name):
    start_room = next(k for k, r in rooms.items() for b in r.bases if b["start"])
    sb = next(b for b in rooms[start_room].bases if b["start"])
    start = (start_room, (sb["c0"] + sb["c1"]) // 2 - 1, (sb["r0"] + sb["r1"]) // 2)
    seen = reach_world(rooms, start)
    problems = []
    for k, room in rooms.items():
        for b in room.bases:
            inside = base_inside(b)
            if not any((k, c, r) in seen for c, r in inside):
                problems.append(f"base {b['id']} irraggiungibile")
        for n, c, r in room.keys:
            if (k, c, r) not in seen:
                problems.append(f"chiave {n} irraggiungibile")
    if problems:
        print(f"!! {name}: " + ", ".join(problems))
    return not problems


def draw(rooms):
    lines = []
    for ry in (0, 1):
        for r in range(ROWS):
            row = ""
            for rx in (0, 1):
                room = rooms[(rx, ry)]
                on = room.cells(gate_closed=True)
                marks = {}
                for b in room.bases:
                    for c, rr in base_inside(b):
                        marks[(c, rr)] = "*" if b["final"] else ("s" if b["start"] else "-")
                for t, c, rr in room.enemies:
                    marks[(c, rr)] = "GSDH"[t]
                for n, c, rr in room.keys:
                    marks[(c, rr)] = "k"
                row += "".join(marks.get((c, r), "X" if (c, r) in on else ".") for c in range(COLS)) + " "
            lines.append(row)
    return "\n".join(lines)


def main():
    asm = ["; stanze di OXYGEN 2600: generato da tools/convert_levels.py, non modificare a mano",
           "; formato: vedi tools/convert_levels.py", ""]
    names = []
    ok = True
    total = 0
    for li, path in enumerate(LEVELS):
        d, rooms = convert(path)
        name = f"L{li + 1} {d.get('name', '')}"
        print(f"\n{name}  luce={d.get('lighting', 'normal')}  nemici tolti={sum(r.dropped for r in rooms.values())}")
        print(draw(rooms))
        ok &= check(d, rooms, name)
        for ry in (0, 1):
            for rx in (0, 1):
                bts = rooms[(rx, ry)].bytes()
                total += len(bts)
                lab = f"room_{li}_{ry * 2 + rx}"
                names.append(lab)
                asm.append(f"{lab}")
                for i in range(0, len(bts), 16):
                    asm.append(" .byte " + ",".join(str(x) for x in bts[i:i + 16]))
    asm.append("room_lo")
    for i in range(0, len(names), 8):
        asm.append(" .byte " + ",".join(f"<{n}" for n in names[i:i + 8]))
    asm.append("room_hi")
    for i in range(0, len(names), 8):
        asm.append(" .byte " + ",".join(f">{n}" for n in names[i:i + 8]))
    # stanza di partenza e luce di ogni livello (bit 2: luce che traballa)
    starts = []
    for path in LEVELS:
        d, rooms = convert(path)
        k = next(k for k, r in rooms.items() for b in r.bases if b["start"])
        flicker = 4 if d.get("lighting", "normal") != "normal" else 0
        starts.append(k[1] * 2 + k[0] | flicker)
    asm.append("level_info")
    asm.append(" .byte " + ",".join(str(x) for x in starts))
    open(OUT, "w").write("\n".join(asm) + "\n")
    print(f"\n{total} byte di stanze + {len(names) * 2 + len(starts)} di tabelle -> {OUT}")
    return ok


if __name__ == "__main__":
    sys.exit(0 if main() else 1)
