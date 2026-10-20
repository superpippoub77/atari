"""Converte i livelli di BLOCK HUNTER 2600 (levels/level*.json) nei dati
della cartuccia (levels.asm) e disegna la tavola dei livelli.

Ogni livello e' una mappa di 16x11 caselle (il bordo e' sempre muro):

  #  muro            .  pavimento      o  buca          :  sabbia
  *  roccia (si distrugge con la dinamite)               D  porta (chiave)
  S  partenza        E  uscita (compare dopo l'ultimo oggetto)
  1-9, a-c  oggetti, nell'ordine in cui compaiono (uno alla volta);
            il tipo e' nella stringa "items": g gemma, k chiave, c cassa
            di dinamite, l cuore (+1 vita), p asse (copre una buca)
  B R V F   pipistrello, ragno, serpente (vipera), fantasma: posizioni di
            partenza; l'ordine in cui entrano e' nella stringa "enemies"
            (2 alla volta; quando uno muore entra il successivo)

Altri campi: "rocks" secondi tra una roccia che cade e l'altra (0 niente),
"boulders" lati da cui entrano i massi (L R U D), "boulder_every" secondi,
"boulder_speed" frame per casella, "light" full / flicker / dark,
"palette" 0-3 (colori dei muri, vedi gen_tables.py), "bg" colore del pavimento.

Formato nella cartuccia (per livello, puntatori lv_lo/lv_hi):
  0  partenza (riga*16 + colonna)       1  uscita
  2  bit 0-1 luce, bit 2-3 tavolozza    3  colore del pavimento
  4  rocce: intervallo in unita' di 16 frame (0 niente)
  5  massi: bit 0-3 lati L R U D, bit 4-7 frame per casella / 2
  6  massi: intervallo in unita' di 16 frame
  7  n nemici (0-4), poi n coppie (tipo, posizione)
  .. n oggetti, poi n coppie (tipo, posizione)
  .. 63 byte: le 9x14 caselle interne, 2 per byte (bit 4-7 la prima)
     codici 0 pavimento, 1 muro, 2 buca, 3 sabbia, 4 roccia, 5 porta

Uso:  python3 convert_levels.py   -> ../levels.asm, ../screenshots/tavola_livelli.png
"""
import glob
import json
import os
import sys
from collections import deque

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
LEVELS = sorted(glob.glob(os.path.join(ROOT, "levels", "level*.json")))
OUT = os.path.join(ROOT, "levels.asm")
PNG = os.path.join(ROOT, "screenshots", "tavola_livelli.png")

W, H = 16, 11
TILE = {".": 0, "#": 1, "o": 2, ":": 3, "*": 4, "D": 5}
ITEM = {"g": 0, "k": 1, "c": 2, "l": 3, "p": 4}
ENEMY = {"B": 0, "R": 1, "V": 2, "F": 3}
LIGHT = {"full": 0, "flicker": 1, "dark": 2}
SIDES = {"L": 1, "R": 2, "U": 4, "D": 8}
LABELS = "123456789abc"
MAX_ITEMS = len(LABELS)
DIRS = [(1, 0), (-1, 0), (0, 1), (0, -1)]


def load(path):
    lv = json.load(open(path))
    rows = lv["map"]
    assert len(rows) == H and all(len(r) == W for r in rows), f"{path}: la mappa deve essere 16x11"
    for y in range(H):
        for x in range(W):
            if (x in (0, W - 1) or y in (0, H - 1)) and rows[y][x] != "#":
                sys.exit(f"{path}: il bordo deve essere muro ({x},{y})")
    return lv


def parse(lv):
    tiles, items, enemies = {}, {}, {}
    start = exit_ = None
    for y, row in enumerate(lv["map"]):
        for x, ch in enumerate(row):
            t = 0
            if ch in TILE:
                t = TILE[ch]
            elif ch == "S":
                start = (x, y)
            elif ch == "E":
                exit_ = (x, y)
            elif ch in LABELS:
                items[LABELS.index(ch)] = (x, y)
            elif ch in ENEMY:
                enemies[ch] = (x, y)
            else:
                sys.exit(f"{lv['name']}: carattere sconosciuto {ch!r}")
            tiles[(x, y)] = t
    kinds = lv["items"]
    assert len(kinds) == len(items) and sorted(items) == list(range(len(items))), \
        f"{lv['name']}: oggetti {sorted(items)} e tipi {kinds!r} non corrispondono"
    for ch in lv["enemies"]:
        assert ch in enemies, f"{lv['name']}: nemico {ch} senza posizione"
    assert start and exit_, f"{lv['name']}: mancano S o E"
    return tiles, [(kinds[i], items[i]) for i in range(len(items))], enemies, start, exit_


def reach(tiles, src, door_open, jumps=True):
    """caselle raggiungibili da src (passi in 4 direzioni e salti di 2 caselle
    sopra buche, rocce o sabbia); -> {casella: True se serve un salto}"""
    def free(p):
        t = tiles.get(p, 1)
        return t in (0, 3) or (t == 5 and door_open)

    seen = {src: False}
    q = deque([src])
    while q:
        p = q.popleft()
        for dx, dy in DIRS:
            n = (p[0] + dx, p[1] + dy)
            if free(n) and n not in seen:
                seen[n] = seen[p]
                q.append(n)
            if not jumps:
                continue
            m = n
            n2 = (p[0] + 2 * dx, p[1] + 2 * dy)
            if tiles.get(m, 1) in (2, 4) and free(n2) and n2 not in seen:
                seen[n2] = True
                q.append(n2)
    return seen


def check(lv, tiles, items, enemies, start, exit_):
    name = lv["name"]
    warn = []
    pos, key = start, False
    for i, (kind, p) in enumerate(items + [("exit", exit_)]):
        if tiles[p] != 0:
            sys.exit(f"{name}: l'oggetto {i + 1} non e' sul pavimento")
        r = reach(tiles, pos, key)
        if p not in r:
            sys.exit(f"{name}: l'oggetto {i + 1} ({kind}) non si raggiunge da {pos}")
        if p not in reach(tiles, pos, key, jumps=False):
            warn.append(f"oggetto {i + 1} solo saltando")
        if kind == "k":
            key = True
        pos = p
    for ch, p in enemies.items():
        if tiles[p] != 0:
            sys.exit(f"{name}: il nemico {ch} non e' sul pavimento")
    if any(t == 5 for t in tiles.values()) and "k" not in lv["items"]:
        sys.exit(f"{name}: c'e' una porta ma nessuna chiave")
    return warn


def pos_byte(p):
    return p[1] * 16 + p[0]


def encode(lv, tiles, items, enemies, start, exit_):
    assert 0 <= lv["palette"] < 4
    b = [pos_byte(start), pos_byte(exit_), LIGHT[lv["light"]] | lv["palette"] << 2, lv["bg"],
         round(lv["rocks"] * 50 / 16)]
    sides = 0
    for ch in lv.get("boulders", ""):
        sides |= SIDES[ch]
    speed = lv.get("boulder_speed", 12)
    b += [sides | (speed // 2) << 4, round(lv.get("boulder_every", 0) * 50 / 16)]
    order = lv["enemies"]
    assert len(order) <= 4
    b.append(len(order))
    for ch in order:
        b += [ENEMY[ch], pos_byte(enemies[ch])]
    b.append(len(items))
    for kind, p in items:
        b += [ITEM[kind], pos_byte(p)]
    inner = [tiles[(x, y)] for y in range(1, H - 1) for x in range(1, W - 1)]
    for i in range(0, len(inner), 2):
        b.append(inner[i] << 4 | inner[i + 1])
    assert all(0 <= v < 256 for v in b)
    return b


def ascii_map(lv):
    return "\n".join("   " + r for r in lv["map"])


def board(levels):
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        return
    s = 4
    pal = [(70, 52, 20), (150, 150, 150), (20, 20, 20), (190, 160, 90), (120, 100, 80), (160, 90, 40)]
    img = Image.new("RGB", (3 * (W * 8 + 8) * s, 2 * (H * 8 + 18) * s), (0, 0, 0))
    d = ImageDraw.Draw(img)
    for n, (lv, (tiles, items, enemies, start, exit_)) in enumerate(levels):
        ox = (n % 3) * (W * 8 + 8) * s + 4 * s
        oy = (n // 3) * (H * 8 + 18) * s + 12 * s
        d.text((ox, oy - 10 * s), f"{n + 1}. {lv['name']}", fill=(255, 255, 255))
        for (x, y), t in tiles.items():
            x0, y0 = ox + x * 8 * s, oy + y * 8 * s
            d.rectangle([x0, y0, x0 + 8 * s - 1, y0 + 8 * s - 1], fill=pal[0])
            pat = {0: "....", 1: "XXXX", 2: "..XX", 3: "X..X", 4: ".XXX", 5: "X.X."}[t]
            for k, ch in enumerate(pat):
                if ch == "X":
                    c = (190, 190, 190) if k < 2 else (30, 30, 30)
                    if t == 5:
                        c = (200, 120, 40)
                    xx, yy = x0 + (k % 2) * 4 * s, y0 + (k // 2) * 4 * s
                    d.rectangle([xx, yy, xx + 4 * s - 1, yy + 4 * s - 1], fill=c)
        for i, (kind, (x, y)) in enumerate(items):
            col = {"g": (80, 220, 255), "k": (255, 220, 0), "c": (230, 60, 40), "l": (255, 90, 160), "p": (200, 140, 70)}[kind]
            d.rectangle([ox + x * 8 * s + 2 * s, oy + y * 8 * s + 2 * s, ox + x * 8 * s + 6 * s, oy + y * 8 * s + 6 * s], fill=col)
            d.text((ox + x * 8 * s + 2 * s, oy + y * 8 * s), LABELS[i], fill=(0, 0, 0))
        for ch, (x, y) in enemies.items():
            d.text((ox + x * 8 * s + 2 * s, oy + y * 8 * s), ch, fill=(255, 80, 80))
        for ch, (x, y) in (("S", start), ("E", exit_)):
            d.text((ox + x * 8 * s + 2 * s, oy + y * 8 * s), ch, fill=(120, 255, 120))
    os.makedirs(os.path.dirname(PNG), exist_ok=True)
    img.save(PNG)


def main():
    out = ["; livelli di BLOCK HUNTER 2600: generato da tools/convert_levels.py, non modificare a mano", ""]
    done = []
    total = 0
    for n, path in enumerate(LEVELS):
        lv = load(path)
        parsed = parse(lv)
        warn = check(lv, *parsed)
        data = encode(lv, *parsed)
        total += len(data)
        done.append((lv, parsed))
        print(f"livello {n + 1}: {lv['name']}  ({len(data)} byte, {len(parsed[1])} oggetti)")
        print(ascii_map(lv))
        for w in warn:
            print("   nota:", w)
        out.append(f"lv{n}")
        for i in range(0, len(data), 16):
            out.append(" .byte " + ",".join(str(v) for v in data[i:i + 16]))
    out.append("lv_lo")
    out.append(" .byte " + ",".join(f"<lv{n}" for n in range(len(LEVELS))))
    out.append("lv_hi")
    out.append(" .byte " + ",".join(f">lv{n}" for n in range(len(LEVELS))))
    open(OUT, "w").write("\n".join(out) + "\n")
    board(done)
    print(f"{len(LEVELS)} livelli, {total + 2 * len(LEVELS)} byte")


if __name__ == "__main__":
    main()
