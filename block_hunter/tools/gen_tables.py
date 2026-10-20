"""Genera gfx.asm (banco 2 di BLOCK HUNTER 2600): tavolozze del playfield,
striscia della lampada (livello buio), arcobaleno del titolo e sprite.

Una sola pagina: striscia della lampada, arcobaleno e 4 tavolozze.
Il kernel di batari Basic con pfcolors e pfres=22 legge il colore della
riga r (1-21) a puntatore+44+4*(r-1): le tavolozze hanno passo 4 e se ne
intrecciano fino a 4 nella stessa pagina. Il puntatore (base-44) deve
avere il byte basso <= 127, se no l'indirizzo cambia pagina, il kernel
perde un ciclo e le righe si spostano. Il colore della riga 0 va in
COLUPF prima di drawscreen (tabella pal_row0, nel banco 1).

Le strisce (44 voci) scorrono: con R pari (riga del giocatore o
spostamento dell'arcobaleno, 0-20) il puntatore e' base+44-4*R e la
riga r prende la voce r-R+21.

Scrive anche il titolo (title.inc): l'immagine del playfield 32x22,
4 byte per riga come li legge il kernel (colonne 0-7 dal bit 7, 8-15 dal
bit 0, 16-23 dal bit 7, 24-31 dal bit 0).

Uso: python3 gen_tables.py  -> ../gfx.asm, ../pal.inc, ../title.inc
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "gfx.asm")
INC = os.path.join(HERE, "..", "pal.inc")

# tavolozze dei muri (i livelli le condividono, lo sfondo e' nel livello):
# colori delle righe alte (chiare) dall'alto in basso, riga bassa (scura)
PALETTES = [
    # nome, chiaro (in alto), chiaro (in basso), scuro
    ("roccia", 0x0E, 0x0A, 0x04),
    ("arancio", 0x4C, 0x48, 0x42),
    ("rosso", 0x6C, 0x68, 0x60),
    ("blu", 0x9A, 0x96, 0x92),
]


def palette(top, bot, dark):
    """21 colori per le righe 1-21 (le righe pari sono la meta' alta delle caselle)."""
    out = []
    for r in range(1, 22):
        if r % 2:
            out.append(dark)
        else:
            t = r / 20
            lum = round(((top & 15) * (1 - t) + (bot & 15) * t) / 2) * 2
            out.append((top & 0xF0) | lum)
    return out


def row0(top):
    return top


def dark_strip():
    """lampada: voce 21 = riga del giocatore; righe pari (chiare) a indici dispari"""
    s = []
    for j in range(44):
        d = abs(j - 21)
        light = j % 2 == 1
        if d <= 6:
            lum = [0x0C, 0x0C, 0x0A, 0x08, 0x06, 0x04, 0x02][d]
            s.append(lum if light else 0x00)
        else:
            s.append(0x02 if light else 0x00)
    return s


def rainbow_strip():
    hues = [0x2, 0x4, 0x6, 0x8, 0xA, 0xC, 0xB, 0x9, 0x7, 0x5, 0x3]
    s = []
    for j in range(44):
        h = hues[(j // 2) % len(hues)]
        s.append(h << 4 | (0xE if j % 2 == 0 else 0xA))
    return s


# sprite 8x8, dall'alto in basso
SPRITES = {
    "hero_r0": ["..XXXX..", ".XXXXXXX", "..X.XX..", "..XXXX..", ".XXXXXX.", "X.XXXX.X", "..X..X..", ".XX..XX."],
    "hero_r1": ["..XXXX..", ".XXXXXXX", "..X.XX..", "..XXXX..", ".XXXXXX.", ".XXXXXX.", "...XX...", "..XX.X.."],
    "hero_u0": ["..XXXX..", ".XXXXXX.", "..XXXX..", "..XXXX..", ".XXXXXX.", "X.XXXX.X", "..X..X..", "..X..XX."],
    "hero_u1": ["..XXXX..", ".XXXXXX.", "..XXXX..", "..XXXX..", ".XXXXXX.", "X.XXXX.X", "..X..X..", ".XX..X.."],
    "hero_d0": ["..XXXX..", ".XXXXXX.", "..X..X..", "..XXXX..", ".XXXXXX.", "X.XXXX.X", "..X..X..", ".XX..X.."],
    "hero_d1": ["..XXXX..", ".XXXXXX.", "..X..X..", "..XXXX..", ".XXXXXX.", "X.XXXX.X", "..X..X..", "..X..XX."],
    "hero_j": ["X.XXXX.X", "XXXXXXXX", "..X.XX..", "..XXXX..", "..XXXX..", "..XXXX..", ".X....X.", "X......X"],
    "hero_x": ["........", "........", "........", "X..XX..X", ".X.XX.X.", "XXXXXXXX", ".XXXXXX.", "X.X..X.X"],
    "bat0": ["X......X", "XX....XX", "XXX..XXX", ".XXXXXX.", "..X..X..", "..XXXX..", "...XX...", "........"],
    "bat1": ["........", "........", "..XXXX..", ".XX..XX.", "XXXXXXXX", "X.XXXX.X", "X..XX..X", "........"],
    "spider0": ["X..XX..X", ".X.XX.X.", "..XXXX..", "XXXXXXXX", "..XXXX..", ".X.XX.X.", "X..XX..X", "X......X"],
    "spider1": [".X.XX.X.", ".X.XX.X.", "..XXXX..", "XXXXXXXX", "X.XXXX.X", "X.X..X.X", ".X....X.", ".X....X."],
    "snake0": [".....XX.", "....XXXX", "....X.XX", "...XX...", "..XX....", ".XX..XX.", "XX..XX.X", ".XXXX..."],
    "snake1": [".....XX.", "....XXXX", "....X.XX", "....XX..", "...XX...", "XXXX..X.", "X..XXXX.", "........"],
    "ghost0": ["..XXXX..", ".XXXXXX.", "XX.XX.XX", "XX.XX.XX", "XXXXXXXX", "XXXXXXXX", "XXXXXXXX", "X.XX.XX."],
    "ghost1": ["..XXXX..", ".XXXXXX.", "XX.XX.XX", "XX.XX.XX", "XXXXXXXX", "XXXXXXXX", "XXXXXXXX", ".XX.XX.X"],
}
FONT = {
    "B": ["XXXX.", "X...X", "X...X", "XXXX.", "X...X", "X...X", "XXXX."],
    "L": ["X....", "X....", "X....", "X....", "X....", "X....", "XXXXX"],
    "O": [".XXX.", "X...X", "X...X", "X...X", "X...X", "X...X", ".XXX."],
    "C": [".XXXX", "X....", "X....", "X....", "X....", "X....", ".XXXX"],
    "K": ["X...X", "X..X.", "X.X..", "XX...", "X.X..", "X..X.", "X...X"],
    "H": ["X..X", "X..X", "X..X", "XXXX", "X..X", "X..X", "X..X"],
    "U": ["X..X", "X..X", "X..X", "X..X", "X..X", "X..X", ".XX."],
    "N": ["X..X", "XX.X", "XX.X", "X.XX", "X.XX", "X..X", "X..X"],
    "T": ["XXXX", ".XX.", ".XX.", ".XX.", ".XX.", ".XX.", ".XX."],
    "E": ["XXXX", "X...", "X...", "XXX.", "X...", "X...", "XXXX"],
    "R": ["XXX.", "X..X", "X..X", "XXX.", "X.X.", "X..X", "X..X"],
}


def text_rows(word, col0):
    rows = ["." * 32 for _ in range(7)]
    c = col0
    for ch in word:
        g = FONT[ch]
        for r in range(7):
            rows[r] = rows[r][:c] + g[r] + rows[r][c + len(g[r]):]
        c += len(g[0]) + 1
    return rows


def title_image():
    img = ["." * 32 for _ in range(22)]
    img[1:8] = text_rows("BLOCK", 2)
    img[10:17] = text_rows("HUNTER", 1)
    img[19] = ".X.XX.X..X.XX.X..X.XX.X..X.XX.X."
    img[20] = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    out = []
    for row in img:
        assert len(row) == 32, row
        for k in range(4):
            bits = row[8 * k:8 * k + 8]
            v = 0
            for i, ch in enumerate(bits):
                if ch == "X":
                    v |= (1 << (7 - i)) if k % 2 == 0 else (1 << i)
            out.append(v)
    return out


# nel kernel l'ultimo byte e' la riga in alto
FLIP = True


def main():
    page_a = [0] * 256
    used_a = set()

    def put(page, used, base, values, name):
        assert 44 <= base and base - 44 <= 127, name
        for i, v in enumerate(values):
            off = base + 4 * i
            assert off < 256 and off not in used, (name, off)
            used.add(off)
            page[off] = v

    put(page_a, used_a, 44, dark_strip(), "buio")
    put(page_a, used_a, 45, rainbow_strip(), "arcobaleno")
    slots = [46, 130, 47, 131]
    lines = ["; generato da tools/gen_tables.py, non modificare a mano", ""]
    equ = []
    for n, (name, top, bot, dark) in enumerate(PALETTES):
        put(page_a, used_a, slots[n], palette(top, bot, dark), name)
        equ.append(f"pal{n} = page_a+{slots[n] - 44}")
    lines += [" align 256", "page_a"]
    for i in range(0, 256, 16):
        lines.append(" .byte " + ",".join(f"${v:02X}" for v in page_a[i:i + 16]))
    lines += ["dark_ptr = page_a", "rainbow_ptr = page_a+1"] + equ
    for name, rows in SPRITES.items():
        assert len(rows) == 8 and all(len(r) == 8 for r in rows), name
        data = [int(r.replace("X", "1").replace(".", "0"), 2) for r in rows]
        if FLIP:
            data = data[::-1]
        lines += [" if (<*) > (<(*+7))", " repeat ($100-<*)", " .byte 0", " repend", " endif",
                  f"spr_{name}", " .byte " + ",".join(f"%{v:08b}" for v in data)]
    open(OUT, "w").write("\n".join(lines) + "\n")
    # colore della riga 0 e puntatori delle tavolozze
    inc = ["; generato da tools/gen_tables.py", "pal_row0", " .byte " + ",".join(f"${p[1]:02X}" for p in PALETTES),
           "pal_lo", " .byte " + ",".join(f"<pal{n}" for n in range(len(PALETTES))),
           "pal_hi", " .byte " + ",".join(f">pal{n}" for n in range(len(PALETTES)))]
    open(INC, "w").write("\n".join(inc) + "\n")
    t = title_image()
    lines = ["; generato da tools/gen_tables.py", "title_pf"]
    for i in range(0, len(t), 16):
        lines.append(" .byte " + ",".join(f"${v:02X}" for v in t[i:i + 16]))
    open(os.path.join(HERE, "..", "title.inc"), "w").write("\n".join(lines) + "\n")
    print("gfx.asm e pal.inc scritti")


if __name__ == "__main__":
    main()
