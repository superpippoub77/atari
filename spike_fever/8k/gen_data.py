#!/usr/bin/env python3
# Genera i dati di SPIKE FEVER 2600 8K (4 contro 4): data.inc per il banco della partita (grafica dei giocatori,
# colori, arene sovrapposte, cifre) e title.inc per il banco del titolo (logo grande, scritte, quadro animato).
# Uso: python3 gen_data.py   (scrive data.inc e title.inc)
PH = 12          # altezza dei giocatori in coppie di righe
PAIRS = 84       # coppie di righe dell'area di gioco (168 righe)
FLOOR = 8        # coppia dei piedi
NETTOP = 22      # coppia della fascia alta della rete

out = []
def emit(label, data, per=16):
    out.append(f"{label}")
    for i in range(0, len(data), per):
        out.append("        .byte " + ",".join(f"${v & 255:02X}" for v in data[i:i + per]))

# ---------- giocatori (8x12, rivolti a destra; righe dall'alto) ----------
# ogni riga ha un tipo di colore: H capelli, S pelle, T maglia, P pantaloncini, L gambe, F scarpe
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
 # 8K: corsa a 4 passi, discesa dal salto, seguito della schiacciata, palleggio, muro
 'run3':  ["..XXX...H", "..XXXX..S", "..XXXXX.S", "...XX...S", ".XXXXX..T", ".XXXXXXXT",
           ".XXXXX..T", "..XXXX..T", "..XXXX..P", "..X...X.L", ".X.....XL", "XX......F"],
 'run4':  ["..XXX...H", "..XXXX..S", "..XXXXX.S", "...XX...S", ".XXXXX..T", ".XXXXXX.T",
           "..XXXXX.T", "..XXXX..T", "..XXXX..P", "...XX...L", "..X.X...L", ".XX.XX..F"],
 'fall':  ["..XXX...H", "..XXXX..S", "..XXXXX.S", "X..XX..XS", ".XXXXXX.T", "..XXXX..T",
           "..XXXX..T", "..XXXX..T", "..XXXX..P", "..X..X..L", ".XX..XX.L", "........F"],
 'spike2':["..XXX...H", "..XXXX..S", "..XXXXX.S", "...XX...S", "..XXXXX.T", "..XXXXXXT",
           "..XXXX..T", "..XXXX..T", "..XXXX..P", ".X...X..L", "X.....X.L", "X......XF"],
 'set':   ["..X..X..S", "..XXXX..H", "..XXXX..S", "...XX...S", "..XXXX..T", "..XXXX..T",
           "..XXXX..T", "..XXXX..T", "..XXXX..P", "..X..X..L", "..X..X..L", ".XX..XX.F"],
 'block': ["X......XS", ".X.XX.X.H", ".XXXXXX.S", "..XXXX..S", "..XXXX..T", "..XXXX..T",
           "..XXXX..T", "..XXXX..T", "..XXXX..P", "..X..X..L", "..X..X..L", ".XX..XX.F"],
}
ORDER = ['stand', 'run1', 'run2', 'jump', 'bump', 'spike', 'run3', 'run4', 'fall', 'spike2', 'set', 'block']
UP = ('jump', 'spike', 'set', 'block')      # pose con le braccia in alto (seconda tabella dei colori)
gfx, kinds = [], []
for name in ORDER:
    rows = FR[name]
    assert len(rows) == PH, name
    g = [int(r[:8].replace('X', '1').replace('.', '0'), 2) for r in rows]
    gfx += list(reversed(g))            # memorizzati dal basso verso l'alto
    kinds.append(list(reversed([r[8] for r in rows])))
emit("Gfx", gfx, 12)

# colori NTSC: [squadra sinistra, squadra destra] x [palazzetto, spiaggia]
SETS = [
    dict(H=0xF2, S=0x3C, T=0x44, P=0x0E, L=0x3C, F=0x0E),   # palazzetto, sinistra: maglia rossa
    dict(H=0x1C, S=0x3C, T=0x84, P=0x02, L=0x3C, F=0x0E),   # palazzetto, destra: maglia blu
    dict(H=0x1E, S=0x3C, T=0x38, P=0x86, L=0x3C, F=0x3A),   # spiaggia, sinistra: canotta arancio, piedi nudi
    dict(H=0xF2, S=0x2A, T=0xC8, P=0x56, L=0x2A, F=0x28),   # spiaggia, destra: canotta verde
]
# colori in comune tra i fotogrammi: una tabella per le pose normali e una per quelle con le braccia in alto
CK = [kinds[ORDER.index('stand')], kinds[ORDER.index('jump')]]
for si, cs in enumerate(SETS):
    cols = []
    for k in CK:
        cols += [cs[c] for c in k]
    emit(f"Cols{si}", cols, 12)
out.append("ColSetLo  .byte <Cols0,<Cols1,<Cols2,<Cols3")
out.append("ColSetHi  .byte >Cols0,>Cols1,>Cols2,>Cols3")
out.append("FrameOfs  .byte " + ",".join(str(i * PH) for i in range(len(ORDER))))
out.append("ColOfs    .byte " + ",".join(str(PH if n in UP else 0) for n in ORDER))
for n in ORDER[6:]:  # ogni posa nuova deve avere i tipi di colore di una delle due tabelle
    assert [r[8] for r in FR[n]] == [r[8] for r in FR['jump' if n in UP else 'stand']], n
out.append("RunSeq    .byte 1, 2, 6, 7          ; corsa: 4 passi")

# ---------- arene: per ogni coppia di righe (0 = in basso) colore di fondo, PF0, PF1, PF2, colore del PF ----------
import random
def arena(beach):
    R = random.Random(7 if beach else 3)
    bg, p0, p1, p2, pc = [0] * PAIRS, [0] * PAIRS, [0] * PAIRS, [0] * PAIRS, [0] * PAIRS
    for y in range(PAIRS):
        if beach:
            if y < 7: bg[y] = [0x2A, 0x2A, 0x2C, 0x2C, 0x2C, 0x2E, 0x2E][y]          # sabbia davanti
            elif y == 7: bg[y] = 0x86                                               # nastro del campo
            elif y < 15: bg[y] = [0x2E, 0x2E, 0x3E, 0x3E, 0x2E, 0x3E, 0x2C][y - 8]   # sabbia dietro
            elif y < 29: bg[y] = [0x86, 0x86, 0x88, 0x88, 0x88, 0x8A, 0x8A, 0x9A, 0x9A, 0x9A, 0x9C, 0x9C, 0xAC, 0xAE][y - 15]   # mare
            else:   # cielo: dall'azzurro chiaro all'orizzonte al blu in alto
                t = (y - 29) / (PAIRS - 29)
                bg[y] = [0x9E, 0x9C, 0x9C, 0x9A, 0x9A, 0x98, 0x98, 0x96, 0x86, 0x86, 0x84][min(10, int(t * 11))]
            if 23 <= y <= 28 and y % 2 == 0:   # riflessi sul mare
                p1[y] = R.choice([0x24, 0x42, 0x11, 0x88]); p0[y] = R.choice([0x40, 0x10, 0x80]); pc[y] = 0x0E
            if 29 <= y <= 45:                  # tronchi delle palme ai bordi
                p0[y] = 0x20 if y < 38 else 0x40; pc[y] = 0xF4
            if 46 <= y <= 52:                  # chiome
                w = [0xF0, 0xF0, 0xF0, 0xF0, 0xE0, 0xC0, 0x40][y - 46]
                p0[y] = w; p1[y] = [0xE0, 0xC0, 0xF8, 0x80, 0xC0, 0x00, 0x00][y - 46]; pc[y] = [0xC4, 0xC6, 0xC4, 0xC6, 0xC8, 0xC6, 0xC4][y - 46]
            if 58 <= y <= 72:                  # nuvole
                k = (y - 58)
                p1[y] = [0x00, 0x1C, 0x3E, 0x7F, 0x3E, 0x00, 0, 0, 0, 0x07, 0x0F, 0x1F, 0x0F, 0x00, 0][k]
                p2[y] = [0, 0, 0, 0, 0, 0, 0x0E, 0x1F, 0x3F, 0x1F, 0x0E, 0, 0, 0, 0][k]
                pc[y] = 0x0E
            if 74 <= y <= 80:                  # sole al centro
                p2[y] = [0x80, 0xC0, 0xE0, 0xE0, 0xE0, 0xC0, 0x80][y - 74]; pc[y] = [0x1A, 0x1C, 0x1E, 0x1E, 0x1E, 0x1C, 0x1A][y - 74]
        else:
            if y < 7: bg[y] = [0xF2, 0xF4, 0xF4, 0xF6, 0xF6, 0xF4, 0xF6][y]          # parquet
            elif y == 7: bg[y] = 0x0E                                               # linea del campo
            elif y < 15: bg[y] = [0xF6, 0xF6, 0xF4, 0xF4, 0xF2, 0x02, 0x02][y - 8]   # parquet dietro e base del muro
            elif y < 23: bg[y] = 0x06                                               # muro grigio
            elif y < 31: bg[y] = 0x42 if y not in (23, 30) else 0x00                 # cartelloni rossi
            elif y < 81: bg[y] = 0x04 if (y - 32) % 3 == 2 else 0x02                 # tribune
            else: bg[y] = 0x00
            if 25 <= y <= 28:                  # scritte dei cartelloni
                p1[y] = [0xEE, 0xAA, 0xAE, 0xE8][y - 25]; p0[y] = [0xE0, 0xA0, 0xE0, 0x20][y - 25]; pc[y] = 0x0E
            if 32 <= y <= 79:                  # pubblico a file: magliette (riga bassa), teste (riga alta), gradino
                k = (y - 32) % 3; row = (y - 32) // 3
                sh = 0x55 if row % 2 else 0xAA
                if k == 0: p0[y] = 0xF0; p1[y] = 0xFF ^ R.choice([0, 0x08, 0x40, 0x81]); p2[y] = 0x7F ^ R.choice([0, 0x10, 0x02]); pc[y] = R.choice([0x44, 0x86, 0x1C, 0xC6, 0x0C, 0x56, 0x2A, 0x9A])
                elif k == 1: p0[y] = sh & 0xF0; p1[y] = sh; p2[y] = sh & 0x7F; pc[y] = R.choice([0x3C, 0x3A, 0xF6])
                else: p0[y] = p1[y] = p2[y] = 0; pc[y] = 0
            if y >= 81: p1[y] = 0x33; p2[y] = 0x33; pc[y] = 0x0E                       # luci sul soffitto
        # rete: palo (FLOOR..13), maglie (14..21), fascia (22)
        if FLOOR <= y <= NETTOP:
            if y < 14: p2[y] = 0x80; pc[y] = 0x1E if beach else 0x08
            elif y < NETTOP: p2[y] = 0x80 if y % 2 else 0x00; pc[y] = 0x00
            else: p2[y] = 0x80; pc[y] = 0x0E
            if y >= 14 and y % 2 == 0: p2[y] = 0x00
    return bg, p0, p1, p2, pc

# le 10 tabelle delle arene (84 byte ciascuna) si sovrappongono dove coincidono (soprattutto gli zeri
# del playfield): un unico blocco ArenaBlob molto più corto, e ogni tabella è un'etichetta dentro il blocco
tables = []
for nm, beach in (("I", False), ("B", True)):
    tabs = list(arena(beach))
    tabs[4][5] = 0x1E                  # coppia 5: colore del segno di caduta (oggetto "ball", colore del playfield)
    # colore del playfield: dove la riga non ha playfield il valore non conta (None = qualsiasi)
    tabs[4] = [c if (tabs[1][y] | tabs[2][y] | tabs[3][y]) or y == 5 else None for y, c in enumerate(tabs[4])]
    for lab, tab in zip(("Bg", "Pf0", "Pf1", "Pf2", "Pfc"), tabs):
        tables.append((f"{lab}{nm}", tab))
# il TIA ignora il bit 0 dei colori e il nibble basso di PF0: anche quei bit sono "qualsiasi" (maschere).
# Si prova qualche ordine di inserimento diverso e si tiene il blocco più corto.
def mask_of(lab):
    return 0xF0 if lab.startswith("Pf0") else 0xFE if lab.startswith(("Bg", "Pfc")) else 0xFF
def pack(order):
    blob, offs = [], {}
    for lab, tab in order:
        m = mask_of(lab)
        def ok(o):
            for i, v in enumerate(tab):
                if v is None or o + i >= len(blob) or blob[o + i] is None: continue
                bv, bm = blob[o + i]
                if (v ^ bv) & m & bm: return False
            return True
        o = next(o for o in range(len(blob) + 1) if ok(o))
        for i, v in enumerate(tab):
            if v is None:
                if o + i >= len(blob): blob.append(None)
                continue
            if o + i >= len(blob): blob.append((v & m, m))
            elif blob[o + i] is None: blob[o + i] = (v & m, m)
            else:
                bv, bm = blob[o + i]; blob[o + i] = ((v & m) | (bv & bm & ~m & 0xFF), m | bm)
        offs[lab] = o
    return blob, offs
order = sorted(tables, key=lambda t: -sum(1 for v in t[1] if v is not None))
blob, offs = pack(order)
RS = random.Random(1)
for _ in range(400):
    o = order[:]; RS.shuffle(o)
    b2, f2 = pack(o)
    if len(b2) < len(blob): blob, offs = b2, f2
blob = [None if c is None else c[0] for c in blob]
blob = [0 if v is None else v for v in blob]
emit("ArenaBlob", blob, 16)
for lab, _ in tables:
    out.append(f"{lab} = ArenaBlob + {offs[lab]}")
import sys
print(f"; arene: {len(blob)} byte invece di {84 * len(tables)}", file=sys.stderr)

# ---------- cifre 3x5 per il punteggio (PF1: decine nel nibble alto, unità nel basso) ----------
DIG = [["XXX", "X.X", "X.X", "X.X", "XXX"], [".X.", "XX.", ".X.", ".X.", "XXX"], ["XXX", "..X", "XXX", "X..", "XXX"],
       ["XXX", "..X", ".XX", "..X", "XXX"], ["X.X", "X.X", "XXX", "..X", "..X"], ["XXX", "X..", "XXX", "..X", "XXX"],
       ["XXX", "X..", "XXX", "X.X", "XXX"], ["XXX", "..X", ".X.", ".X.", ".X."], ["XXX", "X.X", "XXX", "X.X", "XXX"],
       ["XXX", "X.X", "XXX", "..X", "XXX"]]
hi, lo = [], []
for d in DIG:
    for r in d:
        v = int(r.replace('X', '1').replace('.', '0') + "0", 2)    # 4 bit: 3 pixel + spazio
        hi.append(v << 4); lo.append(v)
emit("FontLo", lo, 15)   # (il nibble alto si ricava spostando di 4 bit)

open("data.inc", "w").write("\n".join(out) + "\n")
GAME_OUT = out
exec(open("gen_title.py").read())
