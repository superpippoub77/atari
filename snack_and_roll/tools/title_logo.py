"""Logo del titolo di Snack 'n' Roll 8K (kernel del titolo in assembly).

Disegna il logo a caratteri su una griglia di 40 colonne del playfield
(4 pixel ciascuna, playfield asimmetrico: PF0 PF1 PF2 a sinistra e di nuovo
a destra, senza riflesso) e scrive le tabelle per il kernel:

  SNACK   7 righe (8 linee ciascuna): 6 registri per riga, giallo sfumato,
          con le righe di velocita' a sinistra
  AND     sprite bianchi (player 0 = "AN", player 1 = "D", larghi il
          doppio) fra due righe rosse del playfield
  ROLL    7 righe rosse: R e LL nel playfield, la O e' il biscotto
          (player 0), a sinistra la bocca (player 1), a destra il
          cioccolatino (missile 0); gli sprite cambiano a ogni riga, a
          pixel grossi come le lettere

Tutte le tabelle vanno dal basso (indice 0) all'alto, come le leggono i
cicli del kernel che contano all'indietro (riga = linea / 8).

Uso: python3 title_logo.py              -> stampa le tabelle
     python3 title_logo.py --bas        -> sostituisce le tabelle in "Snack and Roll.bas"
     python3 title_logo.py --png FILE   -> anche un'anteprima del logo (PNG)
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BAS = os.path.join(HERE, "..", "Snack and Roll.bas")

ROW_LINES = 8

FONT = {
    "S": [".XXXX", "XX...", "XX...", ".XXX.", "...XX", "...XX", "XXXX."],
    "N": ["XX..X", "XXX.X", "XXXXX", "XX.XX", "XX..X", "XX..X", "XX..X"],
    "A": [".XXX.", "XX.XX", "XX.XX", "XXXXX", "XX.XX", "XX.XX", "XX.XX"],
    "C": [".XXXX", "XX...", "XX...", "XX...", "XX...", "XX...", ".XXXX"],
    "K": ["XX..X", "XX.XX", "XXXX.", "XXX..", "XXXX.", "XX.XX", "XX..X"],
    "R": ["XXXX.", "XX.XX", "XX.XX", "XXXX.", "XXX..", "XX.XX", "XX..X"],
    "L": ["XX...", "XX...", "XX...", "XX...", "XX...", "XX...", "XXXXX"],
}


def place(rows, word, cols):
    for ch, c in zip(word, cols):
        for r, line in enumerate(FONT[ch]):
            for k, px in enumerate(line):
                if px == "X":
                    rows[r][c + k] = "X"


def grid():
    return [["."] * 40 for _ in range(7)]


SNACK = grid()
place(SNACK, "SNACK", [5, 11, 17, 23, 29])
# righe di velocita' a sinistra della S
for r, (c0, c1) in ((1, (1, 3)), (3, (0, 3)), (5, (1, 3))):
    for c in range(c0, c1 + 1):
        SNACK[r][c] = "X"

ROLL = grid()
place(ROLL, "RLL", [11, 24, 30])

# sprite (8 pixel, larghi il doppio), una riga per riga del logo: dall'alto
AN = [".X..X..X", "X.X.XX.X", "XXX.X.XX", "X.X.X..X", "X.X.X..X"]     # righe da 4 linee
D = ["XXX.....", "X..X....", "X..X....", "X..X....", "XXX....."]
LINE = [0, 0, 0x3F, 0, 0]
# firma sotto il terreno: "by" (player 0) e "FM" (player 1, la F larga 2)
BY = ["X.......", "X...X.X.", "XXX.X.X.", "X.X..X..", "XXX.X..."]
FM = ["XX.X...X", "X..XX.XX", "XX.X.X.X", "X..X...X", "X..X...X"]          # riga rossa (PF1; PF2 = PF1 & 7) a meta' di AND
COOKIE = ["..XXXX..", ".XXXXXX.", "XXX.X.XX", "XXX.X.XX", ".XXXXXX.", "..XXXX..", "........"]
# bocca: il pixel 6 (bit 1) fa anche da cioccolatino (ENAM0 = la stessa
# riga della bocca), acceso nelle 3 righe in basso
MOUTH = ["........", "........", "........", ".XXXXX..", "X.....X.", "X.XXX.X.", ".XXXXXX."]
CHOC = [2 if len(m) > 6 and m[6] == "X" else 0 for m in MOUTH]
# secondo disegno della bocca (chiusa a meta'): stesso pixel 6, cosi' il
# cioccolatino non cambia; il kernel lo legge 8 byte dopo il primo
MOUTH2 = ["........", "........", "........", "........", ".XXXXXX.", "XXXXXXX.", ".XXXXXX."]
assert [2 if m[6] == "X" else 0 for m in MOUTH2] == CHOC


def pf_bytes(row):
    """6 byte (PF0, PF1, PF2 a sinistra e a destra) di una riga di 40 colonne"""
    out = []
    for half in (row[:20], row[20:]):
        pf0 = sum(1 << (4 + i) for i in range(4) if half[i] == "X")
        pf1 = sum(1 << (7 - i) for i in range(8) if half[4 + i] == "X")
        pf2 = sum(1 << i for i in range(8) if half[12 + i] == "X")
        out += [pf0, pf1, pf2]
    return out


def bits(s):
    return int(s.replace("X", "1").replace(".", "0"), 2)


def tables():
    sn = [pf_bytes(r) for r in SNACK][::-1]
    ro = [pf_bytes(r) for r in ROLL][::-1]
    for r in ro:
        assert r[0] == 0 and r[3] == 0, "ROLL non deve usare PF0"
    rows = lambda spr: [bits(x) for x in spr][::-1]
    return sn, ro, rows(COOKIE), rows(MOUTH) + [0] + rows(MOUTH2), CHOC[::-1], rows(AN), rows(D), LINE[::-1], rows(BY), rows(FM)


def asm():
    sn, ro, cookie, mouth, choc, an, d, ln, by, fm = tables()

    def line(label, vals):
        return f"{label}\n .byte " + ",".join(f"${v:02X}" for v in vals)

    out = ["; ---- LOGO: generato da tools/title_logo.py, non modificare a mano ----"]
    for k, name in enumerate(["sn0", "sn1", "sn2", "sn3", "sn4", "sn5"]):
        out.append(line(name, [r[k] for r in sn]))
    assert all(r[1] == 1 for r in ro), "PF1 sinistro di ROLL deve valere 1 (il kernel lo scrive fisso)"
    for k, name in ((2, "ro2"), (4, "ro4"), (5, "ro5")):
        out.append(line(name, [r[k] for r in ro]))
    out.append(line("tk_cookie", cookie))
    out.append(line("tk_mouth", mouth))
    out.append(line("tk_an", an))
    out.append(line("tk_d", d))
    out.append(line("tk_line", ln))
    out.append(line("tk_by", by))
    out.append(line("tk_fm", fm))
    out.append("; ---- fine del logo ----")
    return "\n".join(out)


def preview(path):
    from PIL import Image, ImageDraw
    W, H = 160, 200
    img = Image.new("RGB", (W, H), (0, 0, 0))
    d = ImageDraw.Draw(img)
    yel = [(252, 232, 150), (240, 214, 120), (228, 196, 96), (216, 180, 72), (204, 164, 52), (192, 150, 36), (180, 136, 20)]
    red, white, mouthc, cook = (220, 60, 50), (236, 236, 236), (230, 110, 60), (232, 196, 70)
    L = ROW_LINES
    y0 = 4
    for r in range(7):
        for c in range(40):
            if SNACK[r][c] == "X":
                d.rectangle([4 * c, y0 + r * L, 4 * c + 3, y0 + r * L + L - 1], fill=yel[r])
    y1 = y0 + 7 * L + 6
    for spr, x in ((AN, 72), (D, 88)):
        for i, row in enumerate(spr):
            for k, ch in enumerate(row):
                if ch == "X":
                    d.rectangle([x + 2 * k, y1 + 2 * i, x + 2 * k + 1, y1 + 2 * i + 1], fill=white)
    d.rectangle([24, y1 + 8, 59, y1 + 11], fill=red)
    d.rectangle([104, y1 + 8, 139, y1 + 11], fill=red)
    y2 = y1 + 10 + 4
    for r in range(7):
        for c in range(40):
            if ROLL[r][c] == "X":
                d.rectangle([4 * c, y2 + r * L, 4 * c + 3, y2 + r * L + L - 1], fill=red)
        for spr, x, col in ((COOKIE, 72, cook), (MOUTH, 16, mouthc)):
            for k, ch in enumerate(spr[r]):
                if ch == "X":
                    d.rectangle([x + 2 * k, y2 + r * L, x + 2 * k + 1, y2 + r * L + L - 1], fill=col)
        if CHOC[r]:
            d.rectangle([144, y2 + r * L, 151, y2 + r * L + L - 1], fill=cook)
    y3 = y2 + 7 * L
    d.rectangle([52, y3, 55, y3 + 2], fill=(220, 180, 80))
    d.rectangle([0, y3 + 3, 159, y3 + 5], fill=(220, 180, 80))
    y4 = y3 + 6 + 10
    for spr, x in ((BY, 72), (FM, 92)):
        for i, row in enumerate(spr):
            for k, ch in enumerate(row):
                if ch == "X":
                    d.rectangle([x + 2 * k, y4 + 4 * i, x + 2 * k + 1, y4 + 4 * i + 3], fill=(170, 170, 170))
    img = img.resize((W * 4, H * 4), Image.NEAREST)
    img.save(path)


def main():
    text = asm()
    if "--bas" in sys.argv:
        s = open(BAS, encoding="latin-1").read()
        a = s.index("; ---- LOGO: generato")
        b = s.index("; ---- fine del logo ----") + len("; ---- fine del logo ----")
        s = s[:a] + text + s[b:]
        open(BAS, "w", encoding="latin-1").write(s)
        print("tabelle aggiornate in", BAS)
    else:
        print(text)
    if "--png" in sys.argv:
        preview(sys.argv[sys.argv.index("--png") + 1])


if __name__ == "__main__":
    main()
