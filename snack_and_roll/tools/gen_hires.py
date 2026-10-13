"""Schermate ad alta risoluzione di Snack 'n' Roll 16K (titolo).

Usa la tecnica dello "sprite a 48 pixel": i due player, ripetuti 3 volte
ciascuno (NUSIZ = 3) e col ritardo verticale (VDELP0/VDELP1), disegnano una
riga larga 48 pixel ad alta risoluzione. Ogni riga del disegno occupa 2 righe
dello schermo: nella seconda si cambia il colore per la riga successiva, cosi'
ogni riga ha il suo colore (sfumature).

Uso:  python3 gen_hires.py  -> stampa il codice del banco 3 (routine
__title_frame e tabelle), da mettere nel .bas tra i marcatori.
"""
import math

W = 48

# ---------------------------------------------------------------- disegni
SNACK = """
.XXXXXX.....XXX..XXX.....XXXX.....XXXXXX...XXX..X
XXXXXXXX....XXXX.XXX....XXXXXX...XXXXXXXX..XXX.XX
XXX..XXX....XXXXXXXX...XXX..XXX..XXX..XXX..XXXXX.
XXX.........XXXXXXXX...XXX..XXX..XXX.......XXXX..
XXXXX.......XXX.XXXX...XXX..XXX..XXX.......XXX...
.XXXXXX.....XXX..XXX...XXXXXXXX..XXX.......XXXX..
...XXXXX....XXX..XXX...XXXXXXXX..XXX.......XXXXX.
.....XXX....XXX..XXX...XXX..XXX..XXX.......XXXXXX
XXX..XXX....XXX..XXX...XXX..XXX..XXX..XXX..XXX.XX
XXXXXXXX....XXX..XXX...XXX..XXX..XXXXXXXX..XXX..X
.XXXXXX.....XXX..XXX...XXX..XXX...XXXXXX...XXX..X
"""


def letters(spec):
    rows = [r for r in spec.strip("\n").split("\n")]
    return rows


# lettere del logo (larghe 8, alte 11)
L8 = {
    "S": [".XXXXXX.", "XXXXXXXX", "XXX..XXX", "XXX.....", "XXXXX...", ".XXXXXX.",
          "...XXXXX", ".....XXX", "XXX..XXX", "XXXXXXXX", ".XXXXXX."],
    "N": ["XXX..XXX", "XXXX.XXX", "XXXXXXXX", "XXXXXXXX", "XXX.XXXX", "XXX..XXX",
          "XXX..XXX", "XXX..XXX", "XXX..XXX", "XXX..XXX", "XXX..XXX"],
    "A": ["..XXXX..", ".XXXXXX.", "XXX..XXX", "XXX..XXX", "XXX..XXX", "XXXXXXXX",
          "XXXXXXXX", "XXX..XXX", "XXX..XXX", "XXX..XXX", "XXX..XXX"],
    "C": [".XXXXXX.", "XXXXXXXX", "XXX..XXX", "XXX.....", "XXX.....", "XXX.....",
          "XXX.....", "XXX.....", "XXX..XXX", "XXXXXXXX", ".XXXXXX."],
    "K": ["XXX..XXX", "XXX.XXX.", "XXXXXX..", "XXXXX...", "XXXX....", "XXXX....",
          "XXXXX...", "XXXXXX..", "XXX.XXX.", "XXX..XXX", "XXX..XXX"],
}
R11 = ["XXXXXXXXX..", "XXXXXXXXXX.", "XXX....XXX.", "XXX....XXX.", "XXXXXXXXXX.",
       "XXXXXXXXX..", "XXX..XXX...", "XXX...XXX..", "XXX....XXX.", "XXX.....XXX",
       "XXX.....XXX"]
O11 = ["..XXXXXXX..", ".XXXXXXXXX.", "XXXX...XXXX", "XXX.....XXX", "XXX.....XXX",
       "XXX.....XXX", "XXX.....XXX", "XXX.....XXX", "XXXX...XXXX", ".XXXXXXXXX.",
       "..XXXXXXX.."]


def blank(h):
    return [["."] * W for _ in range(h)]


def put(img, x, y, rows):
    for r, line in enumerate(rows):
        for c, ch in enumerate(line):
            if ch == "X" and 0 <= x + c < W:
                img[y + r][x + c] = "X"


def snack():
    img = blank(11)
    for i, ch in enumerate("SNACK"):
        put(img, i * 10, 0, L8[ch])
    return img


def roll(sway):
    """ROLL con le due L piegate: sway = spostamento della cima (colonne,
    + = destra); il gambo si piega a scalare, la base resta ferma."""
    img = blank(11)
    put(img, 0, 0, R11)
    put(img, 12, 0, O11)
    for x0 in (25, 37):
        for r in range(11):
            if r >= 9:
                put(img, x0, r, ["XXXXXXXXXX"])
            else:
                d = round(sway * (8 - r) / 8)
                put(img, x0 + d, r, ["XXX"])
    return img


# font piccolo 5x7 (scritte)
F5 = {
    "'": ["X", "X", "X", ".", ".", ".", "."],
    "N": ["X...X", "XX..X", "X.X.X", "X..XX", "X...X", "X...X", "X...X"],
    "L": ["X....", "X....", "X....", "X....", "X....", "X....", "XXXXX"],
    "I": [".XXX.", "..X..", "..X..", "..X..", "..X..", "..X..", ".XXX."],
    "V": ["X...X", "X...X", "X...X", "X...X", "X...X", ".X.X.", "..X.."],
    "E": ["XXXXX", "X....", "X....", "XXXX.", "X....", "X....", "XXXXX"],
    "O": [".XXX.", "X...X", "X...X", "X...X", "X...X", "X...X", ".XXX."],
    "B": ["XXXX.", "X...X", "X...X", "XXXX.", "X...X", "X...X", "XXXX."],
    "S": [".XXXX", "X....", "X....", ".XXX.", "....X", "....X", "XXXX."],
    "!": ["..X..", "..X..", "..X..", "..X..", "..X..", ".....", "..X.."],
    " ": ["....."] * 7,
    "1": ["..X..", ".XX..", "..X..", "..X..", "..X..", "..X..", ".XXX."],
    "2": [".XXX.", "X...X", "....X", "...X.", "..X..", ".X...", "XXXXX"],
    "3": ["XXXX.", "....X", "....X", ".XXX.", "....X", "....X", "XXXX."],
    "4": ["...X.", "..XX.", ".X.X.", "X..X.", "XXXXX", "...X.", "...X."],
    "5": ["XXXXX", "X....", "XXXX.", "....X", "....X", "X...X", ".XXX."],
    "6": [".XXX.", "X....", "X....", "XXXX.", "X...X", "X...X", ".XXX."],
}


def glyph(ch):
    """carattere senza colonne vuote ai lati (font a larghezza variabile)."""
    g = F5[ch]
    if ch == " ":
        return ["..", "..", "..", "..", "..", "..", ".."]
    cols = [c for c in range(len(g[0])) if any(r[c] == "X" for r in g)]
    return [r[cols[0]:cols[-1] + 1] for r in g]


def text(s):
    """scritta col font 5x7 a larghezza variabile (1 pixel tra le lettere),
    centrata su 48."""
    gl = [glyph(ch) for ch in s]
    w = sum(len(g[0]) for g in gl) + len(gl) - 1
    assert w <= W, (s, w)
    img = blank(7)
    x = (W - w) // 2
    for g in gl:
        put(img, x, 0, g)
        x += len(g[0]) + 1
    return img


def cookie(frame, nframes=4):
    """biscotto visto di sbieco (ellisse 44x18) con le gocce di cioccolato
    (buchi) che girano: frame = rotazione."""
    h, rx, ry = 18, 21.5, 8.6
    cx, cy = 23.5, 8.5
    img = blank(h)
    for y in range(h):
        for x in range(W):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                img[y][x] = "X"
    chips = [(0.0, 0.55), (1.3, 0.75), (2.4, 0.45), (3.4, 0.8), (4.3, 0.6),
             (5.3, 0.35), (0.7, 0.2), (3.9, 0.15)]
    rot = 2 * math.pi * frame / nframes / 3
    for a, d in chips:
        t = a + rot
        x = round(cx + math.cos(t) * d * rx * 0.85)
        y = round(cy + math.sin(t) * d * ry * 0.8)
        for dx in (-1, 0, 1):
            if 0 <= y < h and 0 <= x + dx < W:
                img[y][x + dx] = "."
    return img


# ------------------------------------------------------------- colori PAL
def grad(cols, n):
    """n colori da una lista di tappe."""
    out = []
    for i in range(n):
        out.append(cols[min(len(cols) - 1, i * len(cols) // n)])
    return out


# blocchi del titolo: nome, varianti, colori (dall'alto), variabile di scelta
BLOCKS = [
    dict(name="snack", variants=[snack()],
         colors=grad([0x2E, 0x2C, 0x2A, 0x28, 0x26, 0x46, 0x44], 11)),
    dict(name="napo", variants=[text("'N'")], colors=[0x0E] * 7),
    dict(name="roll", variants=[roll(0), roll(1), roll(2), roll(-1)],
         colors=grad([0x2E, 0x2C, 0x2A, 0x28, 0x26, 0x46, 0x44], 11),
         # fase = frame/8 (0-5): dritte, poco a destra, tanto, poco, dritte, sinistra
         select=("frame8", [0, 1, 2, 1, 0, 3])),
    dict(name="cookie", variants=[cookie(f) for f in range(4)],
         colors=grad([0x2C, 0x2C, 0x2A, 0x2A, 0x28, 0x28, 0x26, 0x24, 0x22], 18),
         select=("frame4", [i // 3 % 4 for i in range(12)])),
    dict(name="level", variants=[text(f"LIVELLO {n}") if n < 7 else text("BOSS!")
                                  for n in range(1, 8)],
         colors=[0x9E, 0x9E, 0x9C, 0x9C, 0x9A, 0x9A, 0x98],
         select=("level", list(range(7)))),
]
# ordine dei blocchi sullo schermo e righe vuote prima di ognuno
ORDER = ["snack", "napo", "roll", "level", "cookie"]
GAPS = {"snack": 14, "napo": 3, "roll": 3, "level": 10, "cookie": 14}
# pavimento a scacchi in prospettiva (playfield riflesso) sotto il biscotto:
# altezza delle fasce (dall'alto), colore delle piastrelle e dello sfondo
FLOOR = [2, 3, 3, 4, 5, 6, 7, 8, 10, 16]
FLOOR_TILE = 0x64
FLOOR_BG = 0x0C
# parete della cucina dietro al logo
WALL = 0x90


def pf_checker(phase):
    """PF0, PF1, PF2 di mezza riga (20 pixel) a scacchi larghi 2 pixel."""
    bits = [((i // 2) + phase) % 2 for i in range(20)]
    pf0 = sum(bits[i] << (4 + i) for i in range(4))
    pf1 = sum(bits[4 + i] << (7 - i) for i in range(8))
    pf2 = sum(bits[12 + i] << i for i in range(8))
    return pf0, pf1, pf2
VISIBLE = 228

SELECT_CODE = {
    "frame8": " lda _frame_counter\n lsr\n lsr\n lsr\n tax",
    "frame4": " lda _frame_counter\n lsr\n lsr\n tax",
    "level": " ldx _choco_count",
}


def byte(bits):
    return "%" + "".join("1" if b == "X" else "0" for b in bits)


def emit():
    out = []
    o = out.append
    data = []
    total = 0
    tvars = ["temp3", "temp4", "temp5", "temp6"]
    sel_code = []
    for b in BLOCKS:
        R = len(b["variants"][0])
        V = len(b["variants"])
        b["R"] = R
        # tabelle: per ogni variante R+1 voci (la piu' bassa, colore 0, chiude)
        cols = []
        g = [[] for _ in range(6)]
        for v in b["variants"]:
            assert len(v) == R and all(len(r) == W for r in v)
            cols.append(0)
            for k in range(6):
                g[k].append(0)
            for r in range(R - 1, -1, -1):   # dal basso verso l'alto
                for k in range(6):
                    g[k].append(byte(v[r][k * 8:k * 8 + 8]))
            cols += list(reversed(b["colors"]))
        n = len(cols)
        assert n <= 256
        for k in range(6):
            data.append((f"hr_{b['name']}_g{k}", g[k]))
        data.append((f"hr_{b['name']}_c", [f"${c:02X}" for c in cols]))
        starts = [v * (R + 1) + R for v in range(V)]
        if "select" in b:
            var = tvars.pop(0)
            b["var"] = var
            kind, table = b["select"]
            data.append((f"hr_{b['name']}_st", [starts[t] for t in table]))
            sel_code.append(SELECT_CODE[kind] + f"\n lda hr_{b['name']}_st,x\n sta {var}")
        else:
            b["var"] = f"#{starts[0]}"

    o("__title_frame")
    o("   asm")
    o("HR_X = 56          ; x del player0 (il player1 sta 8 pixel piu' a destra)")
    o("HR_VBLANK = 49     ; righe di VBLANK (timer da 64 cicli)")
    o("HR_OVERSCAN = 41   ; righe di overscan (timer da 64 cicli)")
    o("; --- fine dell'overscan, VSYNC, VBLANK ---")
    o("hr_ovs")
    o(" lda INTIM")
    o(" bmi hr_ovs")
    o(" lda #2")
    o(" sta WSYNC")
    o(" sta VSYNC")
    o(" sta WSYNC")
    o(" sta WSYNC")
    o(" sta WSYNC")
    o(" lda #0")
    o(" sta VSYNC")
    o(" lda #2")
    o(" sta VBLANK")
    o(" lda #HR_VBLANK")
    o(" sta TIM64T")
    o(" lda #0")
    for r in ("PF0", "PF1", "PF2", "ENAM0", "ENAM1", "ENABL", "GRP0", "GRP1", "GRP0",
              "REFP0", "REFP1"):
        o(f" sta {r}")
    o(f" lda #${WALL:02X}")
    o(" sta COLUBK")
    o(" lda #3")
    o(" sta NUSIZ0")
    o(" sta NUSIZ1")
    o(" lda #1")
    o(" sta VDELP0")
    o(" sta VDELP1")
    o(" lda #HR_X")
    o(" ldx #0")
    o(" jsr hr_pos")
    o(" lda #HR_X+8")
    o(" ldx #1")
    o(" jsr hr_pos")
    o(" sta WSYNC")
    o(" sta HMOVE")
    for c in sel_code:
        o(c)
    o("hr_vbw")
    o(" lda INTIM")
    o(" bne hr_vbw")
    o(" sta WSYNC")
    o(" lda #0")
    o(" sta VBLANK")
    blocks = {b["name"]: b for b in BLOCKS}
    for b in [blocks[n] for n in ORDER]:
        name, R = b["name"], b["R"]
        gap = GAPS[name]
        total += gap + 2 * R + 2
        o(f"; --- {name}: {gap} righe vuote, poi {R} righe di disegno ---")
        o(f" ldx #{gap}")
        o(f"hr_{name}_gap")
        o(" sta WSYNC")
        o(" dex")
        o(f" bne hr_{name}_gap")
        o(" if (<*) > $70")
        o(f"  jmp hr_{name}_al")
        o("  align 256")
        o(" endif")
        o(f"hr_{name}_al")
        o(" sta WSYNC")
        o(f" lda {b['var']}")
        o(" sta temp1")
        o(" tay")
        o(f" lda hr_{name}_c,y")
        o(" sta COLUP0")
        o(" sta COLUP1")
        o(" sta WSYNC")
        o(f"hr_{name}_loop")
        for half in (0, 1):
            o(" ldy temp1")
            o(f" lda hr_{name}_g0,y")
            o(" sta GRP0")
            o(f" lda hr_{name}_g1,y")
            o(" sta GRP1")
            o(f" lda hr_{name}_g2,y")
            o(" sta GRP0")
            o(f" lda hr_{name}_g5,y")
            o(" sta temp2")
            o(f" ldx hr_{name}_g4,y")
            o(f" lda hr_{name}_g3,y")
            o(" ldy temp2")
            o(" sta GRP1")
            o(" stx GRP0")
            o(" sty GRP1")
            o(" sta GRP0")
            if half == 0:
                o(" sta WSYNC")
        o(" dec temp1")
        o(" ldy temp1")
        o(f" lda hr_{name}_c,y")
        o(" sta COLUP0")
        o(" sta.w COLUP1")
        o(f" bne hr_{name}_loop")
        o(" lda #0")
        o(" sta GRP0")
        o(" sta GRP1")
        o(" sta GRP0")
        o(" sta WSYNC")
    o("; --- pavimento a scacchi ---")
    o(" lda #1")
    o(" sta CTRLPF")
    o(f" lda #${FLOOR_TILE:02X}")
    o(" sta COLUPF")
    for k, h in enumerate(FLOOR):
        pf0, pf1, pf2 = pf_checker(k % 2)
        o(" sta WSYNC")
        if k == 0:
            o(f" lda #${FLOOR_BG:02X}")
            o(" sta COLUBK")
        o(f" lda #${pf0:02X}")
        o(" sta PF0")
        o(f" lda #${pf1:02X}")
        o(" sta PF1")
        o(f" lda #${pf2:02X}")
        o(" sta PF2")
        if h > 1:
            o(f" ldx #{h - 1}")
            o(f"hr_floor{k}")
            o(" sta WSYNC")
            o(" dex")
            o(f" bne hr_floor{k}")
        total += h
    o(" sta WSYNC")
    o(" lda #0")
    o(" sta PF0")
    o(" sta PF1")
    o(" sta PF2")
    o(" sta COLUBK")
    total += 1
    rest = VISIBLE - total
    assert rest >= 0, rest
    if rest:
        o(f"; --- {rest} righe vuote fino in fondo ---")
        o(f" ldx #{rest}")
        o("hr_end_gap")
        o(" sta WSYNC")
        o(" dex")
        o(" bne hr_end_gap")
    o(" lda #2")
    o(" sta VBLANK")
    o(" lda #128+HR_OVERSCAN")
    o(" sta TIM64T")
    o(" jmp hr_done")
    o("; A = x, X = oggetto (0 = player0, 1 = player1)")
    o("hr_pos")
    o(" sta WSYNC")
    o(" sec")
    o("hr_div")
    o(" sbc #15")
    o(" bcs hr_div")
    o(" eor #7")
    o(" asl")
    o(" asl")
    o(" asl")
    o(" asl")
    o(" sta HMP0,x")
    o(" sta RESP0,x")
    o(" rts")
    o("; --- tabelle (nessuna attraversa un confine di pagina) ---")
    for name, vals in data:
        o(f" if (<*) + {len(vals)} > 256")
        o("  align 256")
        o(" endif")
        o(name)
        for i in range(0, len(vals), 16):
            o(" .byte " + ", ".join(str(v) for v in vals[i:i + 16]))
    o("hr_done")
    o("end")
    o("   return otherbank")
    return "\n".join(out)


if __name__ == "__main__":
    print(emit())
