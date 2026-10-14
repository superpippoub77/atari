"""Schermate ad alta risoluzione di Snack 'n' Roll 16K: titolo, cartello di
inizio livello, GAME OVER e vittoria sulla Bocca Gigante.

Usa la tecnica dello "sprite a 48 pixel": i due player, ripetuti 3 volte
ciascuno (NUSIZ = 3) e col ritardo verticale (VDELP0/VDELP1), disegnano una
riga larga 48 pixel ad alta risoluzione. Ogni riga del disegno occupa 2 righe
dello schermo: nella seconda si cambia il colore per la riga successiva, cosi'
ogni riga ha il suo colore (sfumature).

Uso:  python3 gen_hires.py  -> stampa il codice del banco 2 (routine e
tabelle), da mettere nel .bas tra i marcatori (tools/update_bas.py).
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
L8.update({
    "G": [".XXXXXX.", "XXXXXXXX", "XXX..XXX", "XXX.....", "XXX.....", "XXX.XXXX",
          "XXX.XXXX", "XXX..XXX", "XXX..XXX", "XXXXXXXX", ".XXXXXX."],
    "M": ["XX....XX", "XXX..XXX", "XXXXXXXX", "XXXXXXXX", "XX.XX.XX", "XX....XX",
          "XX....XX", "XX....XX", "XX....XX", "XX....XX", "XX....XX"],
    "E": ["XXXXXXXX", "XXXXXXXX", "XXX.....", "XXX.....", "XXXXXX..", "XXXXXX..",
          "XXX.....", "XXX.....", "XXX.....", "XXXXXXXX", "XXXXXXXX"],
    "V": ["XXX..XXX", "XXX..XXX", "XXX..XXX", "XXX..XXX", "XXX..XXX", "XXX..XXX",
          "XXX..XXX", ".XXXXXX.", ".XXXXXX.", "..XXXX..", "...XX..."],
    "R": ["XXXXXXX.", "XXXXXXXX", "XXX..XXX", "XXX..XXX", "XXXXXXXX", "XXXXXXX.",
          "XXXXX...", "XXX.XX..", "XXX..XX.", "XXX..XXX", "XXX..XXX"],
    "O": [".XXXXXX.", "XXXXXXXX", "XXX..XXX", "XXX..XXX", "XXX..XXX", "XXX..XXX",
          "XXX..XXX", "XXX..XXX", "XXX..XXX", "XXXXXXXX", ".XXXXXX."],
    "B": ["XXXXXXX.", "XXXXXXXX", "XXX..XXX", "XXX..XXX", "XXXXXXX.", "XXXXXXX.",
          "XXX..XXX", "XXX..XXX", "XXX..XXX", "XXXXXXXX", "XXXXXXX."],
    "1": ["...XXX..", "..XXXX..", ".XXXXX..", "...XXX..", "...XXX..", "...XXX..",
          "...XXX..", "...XXX..", "...XXX..", ".XXXXXXX", ".XXXXXXX"],
    "2": [".XXXXXX.", "XXXXXXXX", "XXX..XXX", ".....XXX", "....XXXX", "...XXXX.",
          "..XXXX..", ".XXXX...", "XXXX....", "XXXXXXXX", "XXXXXXXX"],
    "3": [".XXXXXX.", "XXXXXXXX", "XXX..XXX", ".....XXX", "...XXXX.", "...XXXX.",
          ".....XXX", ".....XXX", "XXX..XXX", "XXXXXXXX", ".XXXXXX."],
    "4": ["....XXX.", "...XXXX.", "..XXXXX.", ".XX.XXX.", "XX..XXX.", "XXXXXXXX",
          "XXXXXXXX", "....XXX.", "....XXX.", "....XXX.", "....XXX."],
    "5": ["XXXXXXXX", "XXXXXXXX", "XXX.....", "XXX.....", "XXXXXXX.", "XXXXXXXX",
          ".....XXX", ".....XXX", "XXX..XXX", "XXXXXXXX", ".XXXXXX."],
    "6": [".XXXXXX.", "XXXXXXXX", "XXX..XXX", "XXX.....", "XXXXXXX.", "XXXXXXXX",
          "XXX..XXX", "XXX..XXX", "XXX..XXX", "XXXXXXXX", ".XXXXXX."],
})


def big(word):
    """parola a lettere grandi (8x11, 2 pixel tra le lettere), centrata."""
    img = blank(11)
    w = len(word) * 10 - 2
    x0 = (W - w) // 2
    for i, ch in enumerate(word):
        put(img, x0 + i * 10, 0, L8[ch])
    return img


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
    "T": ["XXXXX", "..X..", "..X..", "..X..", "..X..", "..X..", "..X.."],
    "A": [".XXX.", "X...X", "X...X", "XXXXX", "X...X", "X...X", "X...X"],
    "Z": ["XXXXX", "....X", "...X.", "..X..", ".X...", "X....", "XXXXX"],
    "U": ["X...X", "X...X", "X...X", "X...X", "X...X", "X...X", ".XXX."],
    "R": ["XXXX.", "X...X", "X...X", "XXXX.", "X.X..", "X..X.", "X...X"],
    "M": ["X...X", "XX.XX", "X.X.X", "X.X.X", "X...X", "X...X", "X...X"],
    "G": [".XXXX", "X....", "X....", "X..XX", "X...X", "X...X", ".XXXX"],
    "C": [".XXXX", "X....", "X....", "X....", "X....", "X....", ".XXXX"],
    "P": ["XXXX.", "X...X", "X...X", "XXXX.", "X....", "X....", "X...."],
    "H": ["X...X", "X...X", "X...X", "XXXXX", "X...X", "X...X", "X...X"],
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


def bitten():
    """biscotto con un morso a destra e qualche briciola (game over)."""
    img = cookie(0)
    for y in range(len(img)):
        for x in range(W):
            if ((x - 41) / 8.5) ** 2 + ((y - 6) / 5.5) ** 2 <= 1.0:
                img[y][x] = "."
    for x, y in ((44, 14), (40, 16), (46, 11)):
        img[y][x] = "X"
    return img


# ------------------------------------------------------------- colori PAL
def grad(cols, n):
    """n colori da una lista di tappe."""
    out = []
    for i in range(n):
        out.append(cols[min(len(cols) - 1, i * len(cols) // n)])
    return out


GOLD = grad([0x2E, 0x2C, 0x2A, 0x28, 0x26, 0x46, 0x44], 11)
RED = [0x4C, 0x4A, 0x48, 0x48, 0x46, 0x46, 0x44, 0x44, 0x42, 0x42, 0x40]
RAINBOW = [0x2E, 0x3C, 0x5C, 0x7C, 0x9C, 0xBC, 0xDC, 0x8C, 0x6C, 0x4C, 0x2C]
CYAN = [0x9E, 0x9E, 0x9C, 0x9C, 0x9A, 0x9A, 0x98]
WHITE = [0x0E, 0x0E, 0x0C, 0x0C, 0x0A, 0x0A, 0x08]
COOKIE = grad([0x2C, 0x2C, 0x2A, 0x2A, 0x28, 0x28, 0x26, 0x24, 0x22], 18)
NAMES = ["TAVOLI", "TAZZE", "MURETTI", "GOCCE", "SPINGI!", "PRESSE", "GIGANTE"]
NUMBERS = ["1", "2", "3", "4", "5", "6", "BOSS"]

# pezzi delle schermate: varianti (stesse dimensioni) e colori dall'alto
BLOCKS = {
    "snack": dict(variants=[snack()], colors=GOLD),
    "napo": dict(variants=[text("'N'")], colors=[0x0E] * 7),
    "roll": dict(variants=[roll(0), roll(1), roll(2), roll(-1)], colors=GOLD),
    "cookie": dict(variants=[cookie(f, 3) for f in range(3)], colors=COOKIE),
    "level": dict(variants=[text(f"LIVELLO {n}") if n < 7 else text("BOSS!")
                            for n in range(1, 8)], colors=CYAN),
    "livello": dict(variants=[text("LIVELLO")], colors=WHITE),
    "number": dict(variants=[big(n) for n in NUMBERS], colors=GOLD),
    "lname": dict(variants=[text(n) for n in NAMES], colors=CYAN),
    "game": dict(variants=[big("GAME")], colors=RED),
    "over": dict(variants=[big("OVER")], colors=RED),
    "bitten": dict(variants=[bitten()], colors=COOKIE),
    "vinto": dict(variants=[text("HAI VINTO!")], colors=[0x2E, 0x2E, 0x2C, 0x2C, 0x2A, 0x2A, 0x28]),
    "bravo": dict(variants=[big("BRAVO")], colors=RAINBOW),
}
# come si sceglie la variante: codice che mette in X l'indice nella tabella
# delle partenze, e la tabella (indice -> variante)
SELECT = {
    "frame8": (" lda _frame_counter\n lsr\n lsr\n lsr\n tax", [0, 1, 2, 1, 0, 3]),
    "frame4": (" lda _frame_counter\n lsr\n lsr\n tax", [i // 4 % 3 for i in range(12)]),
    "choice": (" ldx _choco_count", list(range(7))),
    "curlevel": (" ldx _level", [0] + list(range(7))),   # livelli 1-7
    "count16": (" lda temp6\n and #15\n tax", [i // 4 % 3 for i in range(16)]),
}
# schermate: (pezzo, righe vuote prima, scelta della variante)
SCREENS = {
    "title": [("snack", 14, None), ("napo", 3, None), ("roll", 3, "frame8"),
              ("level", 10, "choice"), ("cookie", 14, "frame4")],
    "card": [("livello", 18, None), ("number", 6, "curlevel"), ("lname", 8, "curlevel"),
             ("cookie", 16, "count16")],
    "over": [("game", 24, None), ("over", 6, None), ("bitten", 26, None)],
    "win": [("vinto", 20, None), ("bravo", 8, None), ("cookie", 26, "count16")],
}
# pavimento a scacchi in prospettiva (playfield riflesso) in fondo a ogni
# schermata: altezza delle fasce (dall'alto), colori di piastrelle e sfondo
FLOOR = [2, 3, 3, 4, 5, 6, 7, 8, 10, 16]
FLOOR_TILE = 0x64
FLOOR_BG = 0x0C
# parete della cucina dietro alle scritte
WALL = 0x90
VISIBLE = 228
# musichette dei cartelli (AUDC 4, una nota ogni 8 frame, 0 = silenzio)
JINGLES = {
    "card": [29, 23, 19, 14, 0, 19, 14, 14, 14, 0, 0, 0, 0, 0],
    "over": [14, 0, 17, 0, 19, 0, 23, 23, 29, 29, 29, 29, 0, 0, 0, 0, 0, 0, 0],
    "win": [19, 19, 14, 14, 19, 14, 12, 12, 12, 0, 14, 12, 11, 11, 11, 11, 0, 0, 0, 0, 0],
}
# durata dei cartelli in fotogrammi
SHOW_FRAMES = {"card": 110, "over": 150, "win": 160}


def pf_checker(phase):
    """PF0, PF1, PF2 di mezza riga (20 pixel) a scacchi larghi 2 pixel."""
    bits = [((i // 2) + phase) % 2 for i in range(20)]
    pf0 = sum(bits[i] << (4 + i) for i in range(4))
    pf1 = sum(bits[4 + i] << (7 - i) for i in range(8))
    pf2 = sum(bits[12 + i] << i for i in range(8))
    return pf0, pf1, pf2


def byte(bits):
    return "%" + "".join("1" if b == "X" else "0" for b in bits)


BANKS = {
    # banco: (prefisso delle etichette, schermate)
    2: ("h2", ["title", "over"]),
    3: ("h3", ["card", "win"]),
}


def pack(tables):
    """mette le tabelle nelle pagine da 256 byte (prima le piu' grandi), cosi'
    nessuna attraversa un confine di pagina e si spreca poco."""
    pages = []
    for name, vals in sorted(tables, key=lambda t: -len(t[1])):
        for pg in pages:
            if pg[0] + len(vals) <= 256:
                pg[0] += len(vals)
                pg[1].append((name, vals))
                break
        else:
            pages.append([len(vals), [(name, vals)]])
    return [pg[1] for pg in pages]


def emit(bank):
    P, screens = BANKS[bank]
    out = []
    o = out.append
    data = []
    starts = {}
    used = []
    for sname in screens:
        for name, _, sel in SCREENS[sname]:
            if name not in used:
                used.append(name)
    # --- tabelle dei pezzi: per ogni variante R+1 voci (la piu' bassa, con
    # colore 0, chiude il disegno)
    for name in used:
        b = BLOCKS[name]
        R = len(b["variants"][0])
        b["R"] = R
        cols, g = [], [[] for _ in range(6)]
        for v in b["variants"]:
            assert len(v) == R and all(len(r) == W for r in v), name
            cols.append(0)
            for k in range(6):
                g[k].append(0)
            for r in range(R - 1, -1, -1):
                for k in range(6):
                    g[k].append(byte(v[r][k * 8:k * 8 + 8]))
            cols += list(reversed(b["colors"]))
        assert len(cols) <= 256
        for k in range(6):
            data.append((f"{P}_{name}_g{k}", g[k]))
        data.append((f"{P}_{name}_c", [f"${c:02X}" for c in cols]))
        starts[name] = [v * (R + 1) + R for v in range(len(b["variants"]))]
    used_sel = set()
    for sname in screens:
        for name, _, sel in SCREENS[sname]:
            if sel:
                used_sel.add((name, sel))
    for name, sel in sorted(used_sel):
        data.append((f"{P}_{name}_{sel}", [starts[name][t] for t in SELECT[sel][1]]))
    for sname in screens:
        if sname in JINGLES:
            notes = JINGLES[sname]
            assert len(notes) * 8 >= SHOW_FRAMES[sname], sname
            data.append((f"{P}_jingle_{sname}", notes))

    if bank == 2:
        o("HR_X = 56          ; x del player0 (il player1 sta 8 pixel piu' a destra)")
        o("HR_VBLANK = 54     ; righe di VBLANK (timer da 64 cicli)")
        o("HR_OVERSCAN = 41   ; righe di overscan (timer da 64 cicli)")
    emit_common(o, P)
    for sname in screens:
        emit_screen(o, P, sname, SCREENS[sname], starts)
        if sname in SHOW_FRAMES:
            emit_show(o, P, sname)
    o("; --- tabelle (nessuna attraversa un confine di pagina) ---")
    for page in pack(data):
        o(" align 256")
        for name, vals in page:
            o(name)
            for i in range(0, len(vals), 16):
                o(" .byte " + ", ".join(str(v) for v in vals[i:i + 16]))
    return "\n".join(out)


def emit_common(o, P):
    """inizio del fotogramma (fine overscan, VSYNC, VBLANK, player al loro
    posto), attesa della fine del VBLANK, pavimento e fine del fotogramma,
    posizione orizzontale."""
    o(f"{P}_begin")
    o(f"{P}_ovs")
    o(" lda INTIM")
    o(f" bmi {P}_ovs")
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
    o(f" jsr {P}_pos")
    o(" lda #HR_X+8")
    o(" ldx #1")
    o(f" jsr {P}_pos")
    o(" sta WSYNC")
    o(" sta HMOVE")
    o(" rts")
    o(f"{P}_vbwait")
    o(" lda INTIM")
    o(f" bne {P}_vbwait")
    o(" sta WSYNC")
    o(" lda #0")
    o(" sta VBLANK")
    o(" rts")
    o("; X = righe vuote prima del pavimento")
    o(f"{P}_floor")
    o(" sta WSYNC")
    o(" dex")
    o(f" bne {P}_floor")
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
            o(f"{P}_floor{k}")
            o(" sta WSYNC")
            o(" dex")
            o(f" bne {P}_floor{k}")
    o(" sta WSYNC")
    o(" lda #0")
    o(" sta PF0")
    o(" sta PF1")
    o(" sta PF2")
    o(" sta COLUBK")
    o(" lda #2")
    o(" sta VBLANK")
    o(" lda #128+HR_OVERSCAN")
    o(" sta TIM64T")
    o(" rts")
    o("; A = x, X = oggetto (0 = player0, 1 = player1)")
    o(f"{P}_pos")
    o(" sta WSYNC")
    o(" sec")
    o(f"{P}_div")
    o(" sbc #15")
    o(f" bcs {P}_div")
    o(" eor #7")
    o(" asl")
    o(" asl")
    o(" asl")
    o(" asl")
    o(" sta HMP0,x")
    o(" sta RESP0,x")
    o(" rts")


def emit_screen(o, P, sname, scr, starts):
    """un fotogramma completo (VSYNC, VBLANK, 228 righe, avvio overscan)."""
    tvars = ["temp3", "temp4", "temp5"]
    var = {}
    o(f"; ===== schermata {sname} =====")
    o(f"{P}_{sname}")
    o(f" jsr {P}_begin")
    for name, _, sel in scr:
        if sel:
            v = tvars.pop(0)
            var[(name, sel)] = v
            o(SELECT[sel][0])
            o(f" lda {P}_{name}_{sel},x")
            o(f" sta {v}")
    o(f" jsr {P}_vbwait")
    total = 0
    for i, (name, gap, sel) in enumerate(scr):
        R = BLOCKS[name]["R"]
        lab = f"{P}_{sname}{i}"
        src = var[(name, sel)] if sel else f"#{starts[name][0]}"
        total += gap + 2 * R + 2
        o(f"; --- {name}: {gap} righe vuote, poi {R} righe di disegno ---")
        o(f" ldx #{gap}")
        o(f"{lab}_gap")
        o(" sta WSYNC")
        o(" dex")
        o(f" bne {lab}_gap")
        # il ciclo di disegno non deve attraversare un confine di pagina
        # (un salto tra due pagine costa un ciclo in piu' e sfasa le scritture)
        o(" if (<*) > $94")
        o(f"  jmp {lab}_al")
        o("  align 256")
        o(" endif")
        o(f"{lab}_al")
        o(f" lda {src}")
        o(" sta temp1")
        o(" tay")
        o(f" lda {P}_{name}_c,y")
        o(" sta COLUP0")
        o(" sta COLUP1")
        o(" sta WSYNC")
        o(f"{lab}_loop")
        for half in (0, 1):
            o(" ldy temp1")
            o(f" lda {P}_{name}_g0,y")
            o(" sta GRP0")
            o(f" lda {P}_{name}_g1,y")
            o(" sta GRP1")
            o(f" lda {P}_{name}_g2,y")
            o(" sta GRP0")
            o(f" lda {P}_{name}_g5,y")
            o(" sta temp2")
            o(f" ldx {P}_{name}_g4,y")
            o(f" lda {P}_{name}_g3,y")
            o(" ldy temp2")
            o(" sta GRP1")
            o(" stx GRP0")
            o(" sty GRP1")
            o(" sta GRP0")
            if half == 0:
                o(" sta WSYNC")
        o(" dec temp1")
        o(" ldy temp1")
        o(f" lda {P}_{name}_c,y")
        o(" sta COLUP0")
        o(" sta.w COLUP1")
        o(f" bne {lab}_loop")
        o(f"{lab}_end")
        o(f" if >{lab}_loop != >{lab}_end")
        o(f'  echo "ERRORE: il ciclo {lab} attraversa una pagina"')
        o("  err")
        o(" endif")
        o(" lda #0")
        o(" sta GRP0")
        o(" sta GRP1")
        o(" sta GRP0")
        o(" sta WSYNC")
    rest = VISIBLE - total - sum(FLOOR) - 1
    assert rest >= 1, (sname, rest)
    o(f" ldx #{rest}")
    o(f" jmp {P}_floor")


def emit_show(o, P, sname):
    """cartello: la schermata per un certo numero di fotogrammi, con la sua
    musichetta sul canale 1 (temp6 = fotogrammi che mancano)."""
    frames = SHOW_FRAMES[sname]
    o(f"; --- cartello {sname}: {frames} fotogrammi ---")
    o(f"{P}_show_{sname}")
    o(f" lda #{frames}")
    o(" sta temp6")
    o(" lda #0")
    o(" sta AUDV0")
    o(f"{P}_show_{sname}_loop")
    o(f" lda #{frames}")
    o(" sec")
    o(" sbc temp6")
    o(" lsr")
    o(" lsr")
    o(" lsr")
    o(" tay")
    o(" ldx #0")
    o(f" lda {P}_jingle_{sname},y")
    o(f" beq {P}_show_{sname}_q")
    o(" ldx #6")
    o(f"{P}_show_{sname}_q")
    o(" sta AUDF1")
    o(" stx AUDV1")
    o(" lda #4")
    o(" sta AUDC1")
    o(f" jsr {P}_{sname}")
    o(" dec temp6")
    o(f" bne {P}_show_{sname}_loop")
    o(" lda #0")
    o(" sta AUDV1")
    o(" sta NUSIZ0")
    o(" sta VDELP1")
    o(" rts")


WRAPPERS = {
    2: r"""
   ; --- un fotogramma del titolo (da __title_frame, dopo la musica) ---
__title_draw
   asm
 jsr h2_title
end
   return otherbank
   ; --- cartelli: restano sullo schermo qualche secondo con la loro
   ; musichetta (canale 1), poi si torna al gioco ---
   ; tutte le vite perse
__gameover_card
   asm
 jsr h2_show_over
end
   return otherbank
""",
    3: r"""
   ; --- cartello di inizio livello: LIVELLO, numero grande, nome dello
   ; schema, con la sua musichetta ---
__level_card
   asm
 jsr h3_show_card
end
   return otherbank
   ; Bocca Gigante sconfitta
__victory_card
   asm
 jsr h3_show_win
end
   return otherbank
""",
}


if __name__ == "__main__":
    import sys
    bank = int(sys.argv[1]) if len(sys.argv) > 1 else 2
    print(WRAPPERS[bank].strip("\n"))
    print("   asm")
    print(emit(bank))
    print("end")
