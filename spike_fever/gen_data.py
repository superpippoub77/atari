#!/usr/bin/env python3
# ============================================================================
#  SPIKE FEVER 2600 - generatore dei dati della cartuccia (16K, 4 banchi)
#  Uso:  python3 gen_data.py      -> scrive bank0.inc, bank1.inc, bank2.inc
#
#  Qui si disegnano: giocatori, colori delle nazionali, le 6 arene (paesaggi),
#  bandiere, scritte (font 3x5) e il logo grande SPIKE FEVER (font 7x9).
#  Colori: palette NTSC del 2600 ($xy: x = tinta, y = luminosità pari 0..E).
# ============================================================================
import random

PH = 12          # altezza dei giocatori (coppie di righe)
PAIRS = 84       # coppie di righe dell'area di gioco
FLOOR = 8        # coppia dei piedi
NETTOP = 22      # fascia alta della rete

def block(label, data, per=16, nocross=False):
    out = []
    if nocross:     # la tabella non deve attraversare un confine di pagina (cicli costanti nel kernel)
        out += [f"        IF ((* & $FF) + {len(data)}) > 256", "        ALIGN 256", "        ENDIF"]
    out.append(label)
    for i in range(0, len(data), per):
        out.append("        .byte " + ",".join(f"${v & 255:02X}" for v in data[i:i + per]))
    return out

B0, B1, B2 = [], [], []   # righe di bank0.inc / bank1.inc / bank2.inc

# ---------------------------------------------------------------- giocatori (8x12, rivolti a destra)
# tipo di colore per riga: H capelli, S pelle, T maglia, P pantaloncini, L gambe, F scarpe (o piedi nudi)
FR = {
 'stand': ["..XXX...H", "..XXXX..S", "..XXXXX.S", "...XX...S", ".XXXXX..T", "XXXXXXX.T",
           "X.XXXX.XT", "..XXXX..T", "..XXXX..P", "..X..X..L", "..X..X..L", ".XX..XX.F"],
 'run1':  ["..XXX...H", "..XXXX..S", "..XXXXX.S", "...XX...S", ".XXXXX..T", ".XXXXXX.T",
           "..XXXXX.T", "..XXXX..T", "..XXXX..P", ".X...X..L", "X.....X.L", "X......XF"],
 'run2':  ["..XXX...H", "..XXXX..S", "..XXXXX.S", "...XX...S", ".XXXXX..T", "XXXXXX..T",
           "X.XXXX..T", "..XXXX..T", "..XXXX..P", "...XX...L", "...X.X..L", "..XX.XX.F"],
 'jump':  [".X.XX.X.S", ".XXXXXX.H", ".XXXXXX.S", "..XXXX..S", "..XXXX..T", "..XXXX..T",
           "..XXXX..T", "..XXXX..T", "..XXXX..P", "..X..X..L", ".X....X.L", ".X....X.F"],
 'bump':  ["..XXX...H", "..XXXX..S", "..XXXXX.S", "...XX...S", ".XXXXX..T", ".XXXXX..T",
           ".XXXXXXXT", "..XXXXXXS", "..XXXX..P", ".XX..XX.L", ".X....X.L", "XX....XXF"],
 'spike': ["......XXS", ".XXX.XX.H", ".XXXXX..S", "..XXX...S", "..XXXX..T", ".XXXXX..T",
           "X.XXXX..T", "..XXXX..T", "..XXXX..P", "..X..X..L", ".X...X..L", ".X....X.F"],
 'dive':  ["........H", "........S", "........T", "........T", "........P", "........L",
           "......XXH", "XX..XXXXS", "XXXXXXX.T", ".XXXXXX.T", "XX..XX..P", "X......XF"],
}
ORDER = ['stand', 'run1', 'run2', 'jump', 'bump', 'spike', 'dive']
gfx, kinds = [], {}
for name in ORDER:
    rows = FR[name]
    assert len(rows) == PH, name
    gfx += list(reversed([int(r[:8].replace('X', '1').replace('.', '0'), 2) for r in rows]))   # dal basso
    kinds[name] = list(reversed([r[8] for r in rows]))
B1 += block("Gfx", gfx, 12)
B0.append("FrameOfs  .byte " + ",".join(str(i * PH) for i in range(len(ORDER))))
# tabella dei colori per fotogramma: 0 normale, 1 braccia in alto, 2 tuffo
CKIND = {'stand': 0, 'run1': 0, 'run2': 0, 'bump': 0, 'jump': 1, 'spike': 1, 'dive': 2}
B0.append("ColOfs    .byte " + ",".join(str(CKIND[n] * PH) for n in ORDER))

# ---------------------------------------------------------------- nazionali
# nome, maglia, pantaloncini, pelle, capelli
NATIONS = [
    ("ITALY",   0x84, 0x0E, 0x3C, 0xF2), ("FRANCE",  0x82, 0x0E, 0x3C, 0xF4),
    ("GERMANY", 0x0C, 0x00, 0x3E, 0x1C), ("SPAIN",   0x44, 0x84, 0x3C, 0x02),
    ("BRAZIL",  0x1E, 0x86, 0xF6, 0x02), ("USA",     0x46, 0x84, 0x3C, 0x1A),
    ("JAPAN",   0x0E, 0x44, 0x3E, 0x00), ("CHINA",   0x42, 0x1E, 0x3E, 0x00),
    ("CUBA",    0x02, 0xC6, 0xF4, 0x00), ("USSR",    0x40, 0x0C, 0x3C, 0x1C),
]
NN = len(NATIONS)
B0.append(f"NNAT = {NN}")
# colori dei giocatori: per nazione x (scarpe, piedi nudi) x (normale, braccia in alto, tuffo) = 12 byte ciascuno
cols = []
for _, sh, so, sk, ha in NATIONS:
    for beach in (0, 1):
        pal = dict(H=ha, S=sk, T=sh, P=so, L=sk, F=(sk - 2 if beach else 0x0E))
        for nm in ('stand', 'jump', 'dive'):
            cols += [pal[c] for c in kinds[nm]]
B1 += block("NatCols", cols, 12)
# offset dei colori: (nazione*2 + spiaggia) * 36
B0.append("NatColLo  .byte " + ",".join(f"<[NatCols+{(i // 2) * 72 + (i % 2) * 36}]" for i in range(NN * 2)))
B0.append("NatColHi  .byte " + ",".join(f">[NatCols+{(i // 2) * 72 + (i % 2) * 36}]" for i in range(NN * 2)))
B0.append("ShirtCol  .byte " + ",".join(f"${n[1]:02X}" for n in NATIONS))

# ---------------------------------------------------------------- arene (6 paesaggi)
# ogni arena: per coppia di righe (0 = in basso) colore di fondo, PF0, PF1, PF2 (playfield riflesso) e colore del PF.
# Righe comuni: 0..6 pavimento/sabbia davanti, 7 linea del campo, rete nelle coppie FLOOR..NETTOP (PF2 bit 7, al centro).
ARENAS = []
def new():
    return dict(bg=[0] * PAIRS, p0=[0] * PAIRS, p1=[0] * PAIRS, p2=[0] * PAIRS, pc=[0] * PAIRS)
def grad(a, y0, y1, colors):
    for y in range(y0, y1 + 1):
        a['bg'][y] = colors[min(len(colors) - 1, (y - y0) * len(colors) // (y1 - y0 + 1))]
def net(a, pole, mesh=0x00, band=0x0E):
    for y in range(FLOOR, NETTOP + 1):
        if y < 14: a['p2'][y] |= 0x80; a['pc'][y] = pole
        elif y < NETTOP: a['p2'][y] = (a['p2'][y] & 0x7F) | (0x80 if y % 2 else 0); a['pc'][y] = mesh
        else: a['p2'][y] |= 0x80; a['pc'][y] = band
def crowd(a, y0, y1, R, shirts, skin=0x3C, dark=0x02, step=0x04):
    for y in range(y0, y1 + 1):
        k = (y - y0) % 3; row = (y - y0) // 3
        sh = 0x55 if row % 2 else 0xAA
        if k == 0:
            a['p0'][y] = 0xF0; a['p1'][y] = 0xFF ^ R.choice([0, 0x08, 0x40, 0x81]); a['p2'][y] = 0x7F ^ R.choice([0, 0x10, 0x02]); a['pc'][y] = R.choice(shirts)
        elif k == 1:
            a['p0'][y] = sh & 0xF0; a['p1'][y] = sh; a['p2'][y] = sh & 0x7F; a['pc'][y] = skin
        a['bg'][y] = step if k == 2 else dark

# 1. BEIJING GYM (Cina): palestra con parquet, spalliere, finestre, travi e luci
a = new(); R = random.Random(1)
grad(a, 0, 6, [0xF4, 0xF6, 0xF6, 0xF8, 0xF6]); a['bg'][7] = 0x0E
grad(a, 8, 14, [0xF8, 0xF6, 0xF4]); grad(a, 15, 60, [0x2C, 0x2C, 0x2A])
for y in range(16, 30): a['p0'][y] = 0xF0 if y % 2 else 0x50; a['pc'][y] = 0xF2     # spalliere ai lati
for y in range(36, 56):                                                             # finestre
    a['p1'][y] = 0x3C if (y - 36) % 10 < 8 else 0; a['p2'][y] = 0x1E if (y - 36) % 10 < 8 else 0
    a['pc'][y] = 0x9C if y < 46 else 0x9A
grad(a, 61, 83, [0x22, 0x20, 0x00])
for y in (64, 70, 76): a['bg'][y] = 0xF2                                            # travi
for y in (78, 79): a['p1'][y] = 0x66; a['p2'][y] = 0x66; a['pc'][y] = 0x0E          # luci
net(a, 0x06); ARENAS.append(("BEIJING", 0, a))

# 2. COPACABANA (Brasile, beach volley): sabbia, mare, Pan di Zucchero, palme, nuvole, sole
a = new(); R = random.Random(2)
for y in range(7): a['bg'][y] = [0x2A, 0x2A, 0x2C, 0x2C, 0x2C, 0x2E, 0x2E][y]
a['bg'][7] = 0x86
for y in range(8, 15): a['bg'][y] = [0x2E, 0x2E, 0x3E, 0x3E, 0x2E, 0x3E, 0x2C][y - 8]
grad(a, 15, 28, [0x86, 0x88, 0x8A, 0x9A, 0x9C, 0xAC])
grad(a, 29, 83, [0x9E, 0x9C, 0x9A, 0x98, 0x96, 0x86, 0x84])
for y in range(23, 29, 2): a['p1'][y] = R.choice([0x24, 0x42, 0x11]); a['p0'][y] = 0x40; a['pc'][y] = 0x0E
for y in range(29, 42):                                                             # Pan di Zucchero (montagne)
    w = [0xFF, 0xFE, 0xFE, 0x7E, 0x7C, 0x3C, 0x3C, 0x38, 0x18, 0x18, 0x18, 0x10, 0x00][y - 29]
    a['p1'][y] = w; a['pc'][y] = 0xC2 if y < 34 else 0xC4
for y in range(29, 46): a['p0'][y] = 0x20 if y < 38 else 0x40; a['pc'][y] = a['pc'][y] or 0xF4
for y in range(46, 53):
    a['p0'][y] = [0xF0, 0xF0, 0xF0, 0xF0, 0xE0, 0xC0, 0x40][y - 46]; a['pc'][y] = 0xC6
for y in range(58, 73):
    k = y - 58
    a['p1'][y] = [0, 0x1C, 0x3E, 0x7F, 0x3E, 0, 0, 0, 0, 0x07, 0x0F, 0x1F, 0x0F, 0, 0][k]
    a['p2'][y] = [0, 0, 0, 0, 0, 0, 0x0E, 0x1F, 0x3F, 0x1F, 0x0E, 0, 0, 0, 0][k]; a['pc'][y] = 0x0E
for y in range(74, 81): a['p2'][y] = [0x80, 0xC0, 0xE0, 0xE0, 0xE0, 0xC0, 0x80][y - 74]; a['pc'][y] = 0x1E
net(a, 0x1E); ARENAS.append(("COPACABANA", 1, a))

# 3. LA ARENA (USA): palazzetto notturno, campo blu, cartelloni a stelle, pubblico, riflettori
a = new(); R = random.Random(3)
grad(a, 0, 6, [0x84, 0x86, 0x86, 0x88]); a['bg'][7] = 0x0E
grad(a, 8, 14, [0x86, 0x84, 0x82]); grad(a, 15, 22, [0x04])
for y in range(23, 31): a['bg'][y] = 0x84 if y not in (23, 30) else 0x00
for y in range(25, 29): a['p1'][y] = [0x22, 0x77, 0x22, 0x55][y - 25]; a['p0'][y] = [0x20, 0x70, 0x20, 0x50][y - 25]; a['pc'][y] = 0x0E
crowd(a, 32, 76, R, [0x44, 0x86, 0x0C, 0x46, 0x84, 0x0E, 0x1C])
for y in range(77, 84): a['bg'][y] = 0x00
for y in (79, 80): a['p1'][y] = 0x99; a['p2'][y] = 0x99; a['pc'][y] = 0x1E
net(a, 0x08); ARENAS.append(("LA ARENA", 0, a))

# 4. CARIBBEAN (Cuba, beach volley al tramonto): cielo viola-arancio, sole che tramonta, palme in controluce
a = new(); R = random.Random(4)
for y in range(7): a['bg'][y] = [0x28, 0x28, 0x2A, 0x2A, 0x2A, 0x2C, 0x2C][y]
a['bg'][7] = 0x44
grad(a, 8, 14, [0x2C, 0x2A, 0x3A, 0x38])
grad(a, 15, 24, [0x62, 0x64, 0x54, 0x46, 0x48])            # mare che riflette il tramonto
grad(a, 25, 83, [0x2C, 0x2A, 0x38, 0x36, 0x46, 0x44, 0x54, 0x52, 0x62, 0x70])
for y in range(16, 22, 2): a['p1'][y] = R.choice([0x24, 0x42, 0x18]); a['pc'][y] = 0x3E
for y in range(25, 32): a['p2'][y] = [0xE0, 0xF0, 0xF0, 0xF8, 0xF0, 0xF0, 0xE0][y - 25]; a['pc'][y] = [0x1E, 0x1E, 0x1C, 0x2C, 0x2C, 0x2A, 0x3A][y - 25]
for y in range(32, 48): a['p0'][y] = 0x20 if y < 41 else 0x40; a['pc'][y] = 0x00          # tronchi in controluce
for y in range(46, 55):
    a['p0'][y] = [0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xE0, 0xC0, 0x80, 0x40][y - 46]
    a['p1'][y] = [0xE0, 0xC0, 0xF8, 0x80, 0xC0, 0x80, 0, 0, 0][y - 46]; a['pc'][y] = 0x00
for y in range(62, 70, 3): a['p1'][y] = 0x0A; a['pc'][y] = 0x00                        # gabbiani
net(a, 0x1E, 0x00, 0x0E); ARENAS.append(("CARIBBEAN", 1, a))

# 5. MT FUJI (Giappone): campo all'aperto in terra rossa, prato, monte Fuji innevato
a = new(); R = random.Random(5)
grad(a, 0, 6, [0x32, 0x34, 0x34, 0x36]); a['bg'][7] = 0x0E
grad(a, 8, 14, [0xC4, 0xC6, 0xC6, 0xC8]); grad(a, 15, 24, [0xC8, 0xCA, 0xB8])
grad(a, 25, 83, [0x9E, 0x9C, 0x9A, 0x98, 0x88, 0x86])
for y in range(25, 66):                                                             # monte Fuji al centro
    h = y - 25; w = max(0, 40 - h)          # semi-larghezza in pixel di playfield (riflesso: centro dello schermo)
    bits = min(8, max(0, (w + 3) // 4))
    a['p2'][y] = (0xFF << (8 - bits)) & 0xFF if bits else 0
    if bits >= 8 and w > 32: a['p1'][y] = (0xFF >> 0) if w >= 40 else ((0xFF << (8 - min(8, (w - 32 + 3) // 4))) & 0xFF) ^ 0  # (base larga)
    a['pc'][y] = 0x0E if h > 28 else (0x9A if h > 24 else 0x94)
for y in range(25, 66):
    if a['p1'][y]:
        n = bin(a['p1'][y]).count('1'); a['p1'][y] = (0xFF >> (8 - n)) & 0xFF     # PF1: bit0 = verso il centro
net(a, 0x06); ARENAS.append(("MT FUJI", 0, a))

# 6. MOSCOW (finale URSS): grande arena rossa, stendardi, pubblico, luci dorate
a = new(); R = random.Random(6)
grad(a, 0, 6, [0x42, 0x44, 0x44, 0x46]); a['bg'][7] = 0x1E
grad(a, 8, 14, [0x44, 0x42, 0x40]); grad(a, 15, 22, [0x02])
for y in range(23, 31): a['bg'][y] = 0x42 if y not in (23, 30) else 0x00
for y in range(25, 29): a['p1'][y] = [0x18, 0x3C, 0x18, 0x24][y - 25]; a['p0'][y] = [0x40, 0xE0, 0x40, 0xA0][y - 25]; a['pc'][y] = 0x1E
crowd(a, 32, 70, R, [0x42, 0x44, 0x0C, 0x1C, 0x40, 0x84])
for y in range(71, 84): a['bg'][y] = 0x40 if y < 80 else 0x00
for y in range(72, 79): a['p0'][y] = 0x60; a['p2'][y] = 0x18 if y > 73 else 0; a['pc'][y] = 0x1E   # stendardi con stella
for y in (81, 82): a['p1'][y] = 0x55; a['p2'][y] = 0x55; a['pc'][y] = 0x1E
net(a, 0x1E); ARENAS.append(("MOSCOW", 0, a))

for i, (_, _, a) in enumerate(ARENAS):
    for k, lab in (('bg', 'Bg'), ('p0', 'Pf0'), ('p1', 'Pf1'), ('p2', 'Pf2'), ('pc', 'Pfc')):
        B1 += block(f"{lab}{i}", a[k], 14)
ptrs = []
for i in range(len(ARENAS)):
    for lab in ('Bg', 'Pf0', 'Pf1', 'Pf2', 'Pfc'):
        ptrs += [f"<{lab}{i}", f">{lab}{i}"]
B0.append("ArenaPtrs .byte " + ",".join(ptrs))
B0.append("ArenaBeach .byte " + ",".join(str(b) for _, b, _ in ARENAS))
B0.append(f"NARENA = {len(ARENAS)}")
# livelli della modalità 1 giocatore: avversario (nazione) e arena; il campione del mondo in finale
LEVELS = [(7, 0), (4, 1), (5, 2), (8, 3), (6, 4), (9, 5)]   # CHN, BRA, USA, CUB, JPN, URS
B0.append("LevelNat  .byte " + ",".join(str(n) for n, _ in LEVELS))
B0.append("LevelArena .byte " + ",".join(str(a) for _, a in LEVELS))
B0.append(f"NLEVEL = {len(LEVELS)}")

# ---------------------------------------------------------------- cifre del punteggio (anche nel banco 0)
DIG = [["XXX", "X.X", "X.X", "X.X", "XXX"], [".X.", "XX.", ".X.", ".X.", "XXX"], ["XXX", "..X", "XXX", "X..", "XXX"],
       ["XXX", "..X", ".XX", "..X", "XXX"], ["X.X", "X.X", "XXX", "..X", "..X"], ["XXX", "X..", "XXX", "..X", "XXX"],
       ["XXX", "X..", "XXX", "X.X", "XXX"], ["XXX", "..X", ".X.", ".X.", ".X."], ["XXX", "X.X", "XXX", "X.X", "XXX"],
       ["XXX", "X.X", "XXX", "..X", "XXX"]]
lo = []
for d in DIG:
    for r in d: lo.append(int(r.replace('X', '1').replace('.', '0') + "0", 2))
B0 += block("FontLo", lo, 15)

# ---------------------------------------------------------------- scritte (playfield asimmetrico: 10 caratteri da 4 pixel)
F3 = {
 'A': ["XXX", "X.X", "XXX", "X.X", "X.X"], 'B': ["XX.", "X.X", "XX.", "X.X", "XX."], 'C': ["XXX", "X..", "X..", "X..", "XXX"],
 'D': ["XX.", "X.X", "X.X", "X.X", "XX."], 'E': ["XXX", "X..", "XX.", "X..", "XXX"], 'F': ["XXX", "X..", "XX.", "X..", "X.."],
 'G': ["XXX", "X..", "X.X", "X.X", "XXX"], 'H': ["X.X", "X.X", "XXX", "X.X", "X.X"], 'I': ["XXX", ".X.", ".X.", ".X.", "XXX"],
 'J': ["..X", "..X", "..X", "X.X", "XXX"], 'K': ["X.X", "X.X", "XX.", "X.X", "X.X"], 'L': ["X..", "X..", "X..", "X..", "XXX"],
 'M': ["X.X", "XXX", "XXX", "X.X", "X.X"], 'N': ["XX.", "X.X", "X.X", "X.X", "X.X"], 'O': ["XXX", "X.X", "X.X", "X.X", "XXX"],
 'P': ["XXX", "X.X", "XXX", "X..", "X.."], 'R': ["XX.", "X.X", "XX.", "X.X", "X.X"], 'S': ["XXX", "X..", "XXX", "..X", "XXX"],
 'T': ["XXX", ".X.", ".X.", ".X.", ".X."], 'U': ["X.X", "X.X", "X.X", "X.X", "XXX"], 'V': ["X.X", "X.X", "X.X", "X.X", ".X."],
 'W': ["X.X", "X.X", "XXX", "XXX", "X.X"], 'Y': ["X.X", "X.X", ".X.", ".X.", ".X."], 'Z': ["XXX", "..X", ".X.", "X..", "XXX"],
 '?': ["XXX", "..X", ".X.", "...", ".X."], '!': [".X.", ".X.", ".X.", "...", ".X."], ' ': ["...", "...", "...", "...", "..."],
}
for i, d in enumerate(DIG): F3[str(i)] = d

def pf6(bits40):
    """40 pixel -> 6 byte di playfield asimmetrico (PF0,PF1,PF2 a sinistra, poi a destra)"""
    def half(b):
        v = [1 if c == 'X' else 0 for c in b]
        return (sum(v[i] << (4 + i) for i in range(4)), sum(v[4 + i] << (7 - i) for i in range(8)), sum(v[12 + i] << i for i in range(8)))
    return half(bits40[:20]) + half(bits40[20:])

def text_rows(s):
    s = s[:10]
    pad = (10 - len(s)) * 2                     # centrato (in pixel)
    rows = []
    for r in range(5):
        line = "".join(F3[c][r] + "." for c in s)
        line = ("." * pad + line + "." * 40)[:40]
        rows.append(line)
    return rows

def colmajor(rows):
    cols = [[], [], [], [], [], []]
    for line in rows:
        for k, v in enumerate(pf6(line)): cols[k].append(v)
    return sum(cols, [])

STRINGS = ["1 PLAYER", "2 PLAYERS", "SPIKECODE", "SELECT", "PLAYER 1", "PLAYER 2", "PUSH FIRE", "ARENA", "VS",
           "GAME OVER", "CONTINUE?", "CHAMPION!", "WINNER", "AI  2026"]
STRINGS += [f"STAGE {i + 1}" for i in range(len(LEVELS))]
STRINGS += [n[0] for n in NATIONS] + [a[0] for a in ARENAS]
SID = {s: i for i, s in enumerate(STRINGS)}
for i, s in enumerate(STRINGS):
    B2 += block(f"Str{i}", colmajor(text_rows(s)), 15, True)
B2.append("StrLo  .byte " + ",".join(f"<Str{i}" for i in range(len(STRINGS))))
B2.append("StrHi  .byte " + ",".join(f">Str{i}" for i in range(len(STRINGS))))
for k, v in (("S_1P", "1 PLAYER"), ("S_2P", "2 PLAYERS"), ("S_SC", "SPIKECODE"), ("S_SEL", "SELECT"), ("S_P1", "PLAYER 1"),
             ("S_P2", "PLAYER 2"), ("S_FIRE", "PUSH FIRE"), ("S_ARENA", "ARENA"), ("S_VS", "VS"), ("S_OVER", "GAME OVER"),
             ("S_CONT", "CONTINUE?"), ("S_CHAMP", "CHAMPION!"), ("S_WIN", "WINNER"), ("S_AI", "AI  2026"), ("S_STAGE", "STAGE 1"),
             ("S_NAT", NATIONS[0][0]), ("S_ARN", ARENAS[0][0])):
    B0.append(f"{k} = {SID[v]}")

# ---------------------------------------------------------------- logo grande SPIKE / FEVER (font 7x9, 5 lettere da 8 pixel)
BIG = {
 'S': [".XXXXX.", "XXXXXXX", "XX...XX", "XXXX...", ".XXXXX.", "...XXXX", "XX...XX", "XXXXXXX", ".XXXXX."],
 'P': ["XXXXXX.", "XXXXXXX", "XX...XX", "XX...XX", "XXXXXXX", "XXXXXX.", "XX.....", "XX.....", "XX....."],
 'I': ["XXXXXXX", "XXXXXXX", "..XXX..", "..XXX..", "..XXX..", "..XXX..", "..XXX..", "XXXXXXX", "XXXXXXX"],
 'K': ["XX...XX", "XX..XX.", "XX.XX..", "XXXX...", "XXX....", "XXXX...", "XX.XX..", "XX..XX.", "XX...XX"],
 'E': ["XXXXXXX", "XXXXXXX", "XX.....", "XXXXX..", "XXXXX..", "XX.....", "XX.....", "XXXXXXX", "XXXXXXX"],
 'F': ["XXXXXXX", "XXXXXXX", "XX.....", "XXXXX..", "XXXXX..", "XX.....", "XX.....", "XX.....", "XX....."],
 'V': ["XX...XX", "XX...XX", "XX...XX", "XX...XX", "XX...XX", ".XX.XX.", ".XX.XX.", "..XXX..", "...X..."],
 'R': ["XXXXXX.", "XXXXXXX", "XX...XX", "XX...XX", "XXXXXX.", "XXXXX..", "XX.XX..", "XX..XX.", "XX...XX"],
}
for lab, word in (("LogoA", "SPIKE"), ("LogoB", "FEVER")):
    rows = ["".join(BIG[c][r] + "." for c in word) for r in range(9)]
    B2 += block(lab, colmajor(rows), 9, True)
# sfumatura del logo come Power Spikes: dal giallo all'arancio al rosso (per riga di lettera)
B2 += block("LogoCol", [0x1E, 0x1E, 0x1C, 0x2C, 0x2A, 0x3A, 0x38, 0x46, 0x44], 16, True)
B2 += block("TxtWhite", [0x0E] * 5, 16, True)
B2 += block("TxtYellow", [0x1E, 0x1E, 0x1C, 0x1C, 0x1A], 16, True)
B2 += block("TxtOrange", [0x2E, 0x2C, 0x2A, 0x38, 0x36], 16, True)
B2 += block("TxtGrey", [0x06] * 5, 16, True)

# ---------------------------------------------------------------- bandiere (12 righe: fondo, PF0, PF1, PF2, COLUP0, COLUP1)
# playfield riflesso + modo SCORE: metà sinistra col colore COLUP0, metà destra COLUP1. 20 pixel di PF per metà.
def pfbits(lo_px, hi_px):
    """pixel di playfield (0..19, metà sinistra; riflessi a destra) -> PF0, PF1, PF2"""
    v = [1 if lo_px <= i <= hi_px else 0 for i in range(20)]
    return (sum(v[i] << (4 + i) for i in range(4)), sum(v[4 + i] << (7 - i) for i in range(8)), sum(v[12 + i] << i for i in range(8)))
def flag(rows):
    cols = [[], [], [], [], [], []]
    for bg, rng, c0, c1 in rows:
        p = pfbits(*rng) if rng else (0, 0, 0)
        for k, v in enumerate((bg,) + p + (c0, c1)): cols[k].append(v)
    return sum(cols, [])
def vtri(a, b, c): return [(b, (0, 6), a, c)] * 12
def htri(cols3, split=(4, 8)):
    return [(cols3[0] if y < split[0] else cols3[1] if y < split[1] else cols3[2], None, 0, 0) for y in range(12)]
FLAGS = {
    "ITALY":   vtri(0xC6, 0x0E, 0x44),
    "FRANCE":  vtri(0x84, 0x0E, 0x44),
    "GERMANY": htri((0x00, 0x42, 0x1E)),
    "SPAIN":   htri((0x42, 0x1E, 0x42), (3, 9)),
    "BRAZIL":  [(0xC6, (19 - w, 19) if w else None, 0x1E, 0x1E) for w in (0, 2, 4, 6, 8, 10, 10, 8, 6, 4, 2, 0)],
    "USA":     [((0x44 if y % 2 == 0 else 0x0E), (0, 7) if y < 7 else None, 0x84, (0x44 if y % 2 == 0 else 0x0E)) for y in range(12)],
    "JAPAN":   [(0x0E, (19 - w, 19) if w else None, 0x44, 0x44) for w in (0, 0, 0, 2, 3, 4, 4, 3, 2, 0, 0, 0)],
    "CHINA":   [(0x42, r, 0x1E, 0x42) for r in (None, (2, 4), (1, 5), (2, 4), (2, 4) if False else (3, 3), None, (7, 7), (8, 8), (8, 8), (7, 7), None, None)],
    "CUBA":    [((0x84 if (y // 2) % 2 == 0 else 0x0E), (0, max(0, 6 - abs(y - 5.5) * 1.1)) if True else None, 0x44, (0x84 if (y // 2) % 2 == 0 else 0x0E)) for y in range(12)],
    "USSR":    [(0x42, r, 0x1E, 0x42) for r in (None, (2, 2), (1, 3), (2, 2), (1, 3), None, None, None, None, None, None, None)],
}
for i, (n, *_r) in enumerate(NATIONS):
    rows = [(bg, (int(r[0]), int(r[1])) if r else None, c0, c1) for bg, r, c0, c1 in FLAGS[n]]
    B2 += block(f"Flag{i}", flag(rows), 12, True)
B2.append("FlagLo .byte " + ",".join(f"<Flag{i}" for i in range(NN)))
B2.append("FlagHi .byte " + ",".join(f">Flag{i}" for i in range(NN)))

# ---------------------------------------------------------------- titolo: giocatori grandi (stessi sprite del gioco)
B2 += block("TGfx", gfx, 12)
tcols = []
for nat, fr in ((0, 'spike'), (5, 'jump')):      # Italia schiaccia, USA mura
    _, sh, so, sk, ha = NATIONS[nat]
    pal = dict(H=ha, S=sk, T=sh, P=so, L=sk, F=0x0E)
    tcols += [pal[c] for c in kinds[fr]]
B2 += block("TCols", tcols, 12)
B2.append("TFrameOfs .byte " + ",".join(str(i * PH) for i in range(len(ORDER))))

# ---------------------------------------------------------------- titolo piccolo nella parte alta durante la dimostrazione
rows = []
for r in range(5):
    rows.append("".join(F3[c][r] + "." for c in "SPIKEFEVER"))
T6 = [[], [], [], [], [], []]
for line in rows:
    for k, v in enumerate(pf6(line)): T6[k].append(v)
for k, lab in enumerate(("TL0", "TL1", "TL2", "TR0", "TR1", "TR2")): B1 += block(lab, T6[k])
B1 += block("TCol", [0x1E, 0x1C, 0x2C, 0x3A, 0x48])

# ---------------------------------------------------------------- salto: altezza per fotogramma (0 = a terra)
jz = [0] + [max(0, int(round(1.156 * t - 0.037 * t * t))) for t in range(1, 32)]
B0 += block("JumpZ", jz, 16)

for name, lines in (("bank0.inc", B0), ("bank1.inc", B1), ("bank2.inc", B2)):
    open(name, "w").write("; generato da gen_data.py: non modificare a mano\n" + "\n".join(lines) + "\n")
print("ok", {"bank1_bytes": len(gfx) + len(cols) + 5 * PAIRS * len(ARENAS), "stringhe": len(STRINGS)})
