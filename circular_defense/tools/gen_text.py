"""Scritte nel playfield (32 x 11) di Circular Defense con un font 3x5.

Uso:  python3 gen_text.py  -> stampa le routine del banco 2 che disegnano
la schermata del titolo, il game over e la vittoria (blocchi "playfield:").
"""

FONT = {
    "A": [".X.", "X.X", "XXX", "X.X", "X.X"],
    "C": [".XX", "X..", "X..", "X..", ".XX"],
    "D": ["XX.", "X.X", "X.X", "X.X", "XX."],
    "E": ["XXX", "X..", "XX.", "X..", "XXX"],
    "F": ["XXX", "X..", "XX.", "X..", "X.."],
    "G": [".XX", "X..", "X.X", "X.X", ".XX"],
    "I": ["XXX", ".X.", ".X.", ".X.", "XXX"],
    "L": ["X..", "X..", "X..", "X..", "XXX"],
    "M": ["X.X", "XXX", "XXX", "X.X", "X.X"],
    "N": ["XX.", "X.X", "X.X", "X.X", "X.X"],
    "O": [".X.", "X.X", "X.X", "X.X", ".X."],
    "R": ["XX.", "X.X", "XX.", "X.X", "X.X"],
    "S": [".XX", "X..", ".X.", "..X", "XX."],
    "T": ["XXX", ".X.", ".X.", ".X.", ".X."],
    "U": ["X.X", "X.X", "X.X", "X.X", "XXX"],
    "V": ["X.X", "X.X", "X.X", "X.X", ".X."],
    " ": ["...", "...", "...", "...", "..."],
}


def word(text):
    """5 righe, lettere larghe 3 separate da 1 colonna, centrate su 32."""
    rows = ["." * 32 for _ in range(5)]
    w = len(text) * 4 - 1
    x0 = (32 - w) // 2
    for i, ch in enumerate(text):
        for r in range(5):
            line = list(rows[r])
            for k in range(3):
                if FONT[ch][r][k] == "X":
                    line[x0 + i * 4 + k] = "X"
            rows[r] = "".join(line)
    return rows


def screen(top, bottom=None):
    blank = "." * 32
    if bottom is None:
        rows = [blank] * 3 + word(top) + [blank] * 3
    else:
        rows = word(top) + [blank] + word(bottom)
    return rows


def block(label, rows, comment):
    out = [f"   ; {comment}", label, "   playfield:"]
    out += ["   " + r for r in rows]
    out += ["end", "   return otherbank"]
    return "\n".join(out)


def main():
    print(block("__draw_title", screen("CIRCULAR", "DEFENSE"), "SCRITTA DEL TITOLO"))
    print()
    print(block("__draw_gameover", screen("GAME", "OVER"), "GAME OVER: tutte le citta' distrutte"))
    print()
    print(block("__draw_victory", screen("VITTORIA"), "VITTORIA: superati tutti gli 8 livelli"))


if __name__ == "__main__":
    main()
