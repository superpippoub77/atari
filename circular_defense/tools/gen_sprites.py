"""Genera le grafiche di Circular Defense.bas: la torretta del cannone con la
canna in 8 direzioni e i due fotogrammi del difensore (scudo).

Ogni disegno e' una griglia di testo ('X' = pixel acceso), riga in alto
per prima. Uso:  python3 gen_sprites.py  -> stampa il codice per il BAS
"""
import math

# torretta (20 righe x 8 colonne, disegnata a doppia larghezza con NUSIZ1).
# Misurato in Stella: un pixel orizzontale e' largo 4 punti dello schermo e
# una riga dello sprite e' alta 3,35 punti, quindi una colonna a doppia
# larghezza vale 8 punti. Il corpo e' un cerchio e la canna un rettangolo
# ruotato, calcolati in punti dello schermo: stessa proporzione in tutte
# le 8 direzioni.
ROWS, COLS = 20, 8
CW, RH = 8.0, 3.35
BODY_RX, BODY_RY = 16.5, 16.5         # raggi del corpo (punti dello schermo)
BARREL_FROM, BARREL_TO, BARREL_HALF = 10.0, 33.0, 6.2


def cannon(theta):
    rows = []
    for r in range(ROWS):
        line = ""
        for c in range(COLS):
            x, y = (c - 3.5) * CW, (r - (ROWS - 1) / 2) * RH
            body = (x / BODY_RX) ** 2 + (y / BODY_RY) ** 2 <= 1.0
            along = x * math.cos(theta) + y * math.sin(theta)
            perp = abs(-x * math.sin(theta) + y * math.cos(theta))
            barrel = BARREL_FROM <= along <= BARREL_TO and perp <= BARREL_HALF
            line += "X" if body or barrel else "."
        rows.append(line)
    return rows


NAMES = ["destra", "basso-destra", "basso", "basso-sinistra", "sinistra", "alto-sinistra", "alto", "alto-destra"]

# difensore: sfera di energia, anello + nucleo (8 righe x 8 colonne)
SHIELD = [
    [
        "..XXXX..",
        ".X....X.",
        "X..XX..X",
        "X.XXXX.X",
        "X.XXXX.X",
        "X..XX..X",
        ".X....X.",
        "..XXXX..",
    ],
    [
        "..X..X..",
        ".XX..XX.",
        "...XX...",
        "X.XXXX.X",
        "X.XXXX.X",
        "...XX...",
        ".XX..XX.",
        "..X..X..",
    ],
]


def bits(rows):
    # batari Basic disegna l'ultima riga della lista in alto: si inverte
    return ["   %" + r.replace(".", "0").replace("X", "1") for r in reversed(rows)]


def cannon_frames():
    # 0 = destra, poi in senso orario ogni 45 gradi (y verso il basso)
    return [cannon(math.radians(45 * k)) for k in range(8)]


def main():
    print("   ; --- torretta del cannone: la canna punta verso l'ultimo colpo ---")
    print("   ; (generato da tools/gen_sprites.py)")
    labels = " ".join(f"__cannon{k}" for k in range(8))
    print(f"   on temp2 goto {labels}")
    for k, frame in enumerate(cannon_frames()):
        print(f"__cannon{k}")
        print(f"   ; canna verso {NAMES[k]}")
        print("   player1:")
        print("\n".join(bits(frame)))
        print("end")
        if k < 7:
            print("   goto __cannon_done")
    print("__cannon_done")
    print()
    print("   ; --- difensore: due fotogrammi alternati (luci che girano) ---")
    print("   if _frame & 8 then goto __shield_b")
    print("   player0:")
    print("\n".join(bits(SHIELD[0])))
    print("end")
    print("   goto __shield_done")
    print("__shield_b")
    print("   player0:")
    print("\n".join(bits(SHIELD[1])))
    print("end")
    print("__shield_done")


if __name__ == "__main__":
    main()
