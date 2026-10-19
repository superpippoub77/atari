# Dati del banco del titolo di SPIKE FEVER 2600 8K (eseguito da gen_data.py: usa FR, ORDER, PH, SETS).
# Scrive title.inc: logo grande SPIKE / FEVER (font 7x9, come la 16K), scritte 3x5 del menu, pose e colori del
# quadro animato (schiacciata contro il muro).

T = []


def block(label, data, per=16, nocross=False):
    if nocross:     # la tabella non deve attraversare un confine di pagina (cicli costanti nel kernel)
        T.extend([f"        IF ((* & $FF) + {len(data)}) > 256", "        ALIGN 256", "        ENDIF"])
    T.append(label)
    for i in range(0, len(data), per):
        T.append("        .byte " + ",".join(f"${v & 255:02X}" for v in data[i:i + per]))


def pf6(bits40):
    """40 pixel -> 6 byte di playfield asimmetrico (PF0, PF1, PF2 a sinistra, poi a destra)"""
    def half(b):
        v = [1 if c == 'X' else 0 for c in b]
        return (sum(v[i] << (4 + i) for i in range(4)), sum(v[4 + i] << (7 - i) for i in range(8)),
                sum(v[12 + i] << i for i in range(8)))
    return half(bits40[:20]) + half(bits40[20:])


def colmajor(rows):
    cols = [[], [], [], [], [], []]
    for line in rows:
        for k, v in enumerate(pf6(line)):
            cols[k].append(v)
    return sum(cols, [])


# ---------------------------------------------------------------- logo grande SPIKE / FEVER
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
    block(lab, colmajor(rows), 9, True)
# sfumatura come Power Spikes: dal giallo all'arancio al rosso (NTSC)
block("LogoCol", [0x1E, 0x1E, 0x1C, 0x2C, 0x2A, 0x3A, 0x38, 0x46, 0x44], 16, True)
block("LogoCol2", [0x2E, 0x2E, 0x2C, 0x3C, 0x3A, 0x4A, 0x48, 0x46, 0x44], 16, True)

# ---------------------------------------------------------------- scritte 3x5 del menu
F3 = {
 'A': ["XXX", "X.X", "XXX", "X.X", "X.X"], 'B': ["XX.", "X.X", "XX.", "X.X", "XX."], 'C': ["XXX", "X..", "X..", "X..", "XXX"],
 'D': ["XX.", "X.X", "X.X", "X.X", "XX."], 'E': ["XXX", "X..", "XX.", "X..", "XXX"], 'F': ["XXX", "X..", "XX.", "X..", "X.."],
 'G': ["XXX", "X..", "X.X", "X.X", "XXX"], 'H': ["X.X", "X.X", "XXX", "X.X", "X.X"], 'I': ["XXX", ".X.", ".X.", ".X.", "XXX"],
 'K': ["X.X", "X.X", "XX.", "X.X", "X.X"], 'L': ["X..", "X..", "X..", "X..", "XXX"], 'M': ["X.X", "XXX", "XXX", "X.X", "X.X"],
 'N': ["XX.", "X.X", "X.X", "X.X", "X.X"], 'O': ["XXX", "X.X", "X.X", "X.X", "XXX"], 'P': ["XXX", "X.X", "XXX", "X..", "X.."],
 'R': ["XX.", "X.X", "XX.", "X.X", "X.X"], 'S': ["XXX", "X..", "XXX", "..X", "XXX"], 'T': ["XXX", ".X.", ".X.", ".X.", ".X."],
 'U': ["X.X", "X.X", "X.X", "X.X", "XXX"], 'V': ["X.X", "X.X", "X.X", "X.X", ".X."], 'Y': ["X.X", "X.X", ".X.", ".X.", ".X."],
 'Z': ["XXX", "..X", ".X.", "X..", "XXX"], ' ': ["...", "...", "...", "...", "..."],
 '1': [".X.", "XX.", ".X.", ".X.", "XXX"], '2': ["XXX", "..X", "XXX", "X..", "XXX"], '4': ["X.X", "X.X", "XXX", "..X", "..X"],
}


def text_rows(s):
    s = s[:10]
    pad = (10 - len(s)) * 2                     # centrato (in pixel)
    rows = []
    for r in range(5):
        line = "".join(F3[c][r] + "." for c in s)
        rows.append(("." * pad + line + "." * 40)[:40])
    return rows


STRINGS = ["1 PLAYER", "2 PLAYERS", "4 VS 4", "2 VS 2", "PALAZZETTO", "SPIAGGIA", "PUSH FIRE"]
for i, st in enumerate(STRINGS):
    block(f"Str{i}", colmajor(text_rows(st)), 15, True)
T.append("StrLo  .byte " + ",".join(f"<Str{i}" for i in range(len(STRINGS))))
T.append("StrHi  .byte " + ",".join(f">Str{i}" for i in range(len(STRINGS))))
block("TxtWhite", [0x0E] * 5, 16, True)
block("TxtYellow", [0x1E, 0x1E, 0x1C, 0x1C, 0x1A], 16, True)
block("TxtOrange", [0x2E, 0x2C, 0x2A, 0x38, 0x36], 16, True)
block("TxtBlue", [0x9E, 0x9C, 0x9A, 0x98, 0x96], 16, True)
T.append("ColTabLo .byte <TxtWhite,<TxtYellow,<TxtOrange,<TxtBlue")
T.append("ColTabHi .byte >TxtWhite,>TxtYellow,>TxtOrange,>TxtBlue")

# ---------------------------------------------------------------- quadro animato: pose e colori (squadre del palazzetto)
PIC = ['stand', 'run1', 'run2', 'run3', 'run4', 'jump', 'spike', 'spike2', 'fall', 'block']
pg = []
for name in PIC:
    pg += list(reversed([int(r[:8].replace('X', '1').replace('.', '0'), 2) for r in FR[name]]))
block("TGfx", pg, 12)
T.append("TFrame .byte " + ",".join(str(i * PH) for i in range(len(PIC))))
T.append("TUp    .byte " + ",".join(str(PH if n in UP else 0) for n in PIC))
for si in (0, 1):
    cs = SETS[si]
    cols = []
    for ref in ('stand', 'jump'):
        cols += [cs[c] for c in reversed([r[8] for r in FR[ref]])]
    block(f"TCols{si}", cols, 12)
T.append("PIC_STAND = 0")
T.append("PIC_RUN = 1")
T.append("PIC_JUMP = 5")
T.append("PIC_SPIKE = 6")
T.append("PIC_SPIKE2 = 7")
T.append("PIC_FALL = 8")
T.append("PIC_BLOCK = 9")
# salto: altezza (coppie di righe) per 28 fotogrammi
import math
block("JumpH", [int(round(14 * math.sin(math.pi * i / 27))) for i in range(28)], 14)

# sfondo del quadro (32 coppie di righe, 0 = in basso): parquet, linea, muro blu; rete al centro (PF2 bit 7)
PICP, PFLOOR = 32, 4
bg, pf2, pfc = [], [], []
for y in range(PICP):
    bg.append([0xF4, 0xF6, 0xF4, 0xF6][y] if y < PFLOOR else 0x0E if y == PFLOOR else 0x82 if y < 30 else 0x80)
    if PFLOOR < y < 12:
        pf2.append(0x80); pfc.append(0x08)          # palo
    elif 12 <= y < 18:
        pf2.append(0x80 if y % 2 else 0x00); pfc.append(0x06)   # maglie
    elif y == 18:
        pf2.append(0x80); pfc.append(0x0E)          # fascia
    else:
        pf2.append(0); pfc.append(0)
block("PicBg", bg, 16, True)
block("PicPf2", pf2, 16, True)
block("PicPfc", pfc, 16, True)

open("title.inc", "w").write("\n".join(T) + "\n")
