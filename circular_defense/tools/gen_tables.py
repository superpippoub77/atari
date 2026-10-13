"""Genera le tabelle di Circular Defense.bas.

Coordinate dei missili/ball (come le usa batari Basic):
  colonna del playfield c  -> pixel x = 4*c + 18 .. 4*c + 21
  riga del playfield r     -> y = 8*r .. 8*r + 7
Centro dello schermo: x = 82 (tra le colonne 15 e 16), y = 44 (riga 5).

Le 6 citta' stanno su un anello (ellisse) a 30, 90, 150, 210, 270, 330 gradi.
Ogni citta' e' larga 4 colonne e alta 3 righe: una torre (riga alta), una
fila di palazzi (riga di mezzo) e la base (riga bassa): 8 pezzetti, elencati
dal piu' alto al piu' basso. Un colpo non parato toglie il primo che c'e'.

Proiettili: 64 passi dal centro alla citta'. "Deviati": a meta' strada
(passo 32) un proiettile puo' cambiare bersaglio e andare alla citta'
vicina negli ultimi 32 passi.

Uso:  python3 gen_tables.py bank1|bank2  -> stampa i blocchi "data" di quel banco
"""
import math

X0, Y0 = 82, 44
RX, RY = 56, 40          # anello delle citta'
SX, SY = 28, 20          # orbita del difensore
CITY_ANGLES = [30, 90, 150, 210, 270, 330]
# skyline di ogni citta': (torre, palazzi); 'X' = pezzetto
SKYLINES = [(".X..", "XX.X"), ("..X.", "X.XX"), ("..X.", "X.XX"),
            (".X..", "XX.X"), ("..X.", "XX.X"), (".X..", "X.XX")]
# riga della base di ogni citta' (simmetriche rispetto alla riga 5 del cannone)
BASE_ROWS = [9, 10, 9, 3, 2, 3]
PADDLE_MAX = 77          # escursione del paddle misurata in Stella (0-77)


def cities():
    """(colonna sinistra, riga bassa) di ogni citta'."""
    out = []
    for a in CITY_ANGLES:
        t = math.radians(a)
        ex, ey = X0 + RX * math.cos(t), Y0 + RY * math.sin(t)
        c = round((ex - 18) / 4 - 1.5)
        out.append((min(28, max(0, c)), BASE_ROWS[len(out)]))     # righe rb-2..rb
    # simmetria perfetta: le citta' di destra sono lo specchio di quelle di
    # sinistra (colonna c -> 31 - c - 3)
    for right, left in ((0, 2), (5, 3)):
        out[right] = (31 - out[left][0] - 3, out[left][1])
    return out


def pieces():
    """8 pezzetti per citta' (colonna, riga), dal piu' alto; 255 = vuoto."""
    out = []
    for (c, rb), (tower, mid) in zip(cities(), SKYLINES):
        p = [(c + k, rb - 2) for k in range(4) if tower[k] == "X"]
        p += [(c + k, rb - 1) for k in range(4) if mid[k] == "X"]
        p += [(c + k, rb) for k in range(4)]
        p += [(255, 255)] * (8 - len(p))
        out.append(p)
    return out


def target(k):
    """punto d'arrivo dei proiettili sulla citta' k (centro della riga dei palazzi)."""
    c, rb = cities()[k]
    return 4 * c + 18 + 8, 8 * (rb - 1) + 4


def s16(v):
    v = round(v) & 0xFFFF
    return v >> 8, v & 0xFF


def velocities():
    """indice v: 0-5 = verso la citta' v; 6 + 2*d + s = deviato (prima meta'
    verso d, poi verso la vicina: s=0 -> d+1, s=1 -> d-1)."""
    vx, vy, tc, aim = [], [], [], []
    for d in range(6):
        ex, ey = target(d)
        vx.append((ex - X0) * 256 / 64)
        vy.append((ey - Y0) * 256 / 64)
        tc.append(d)
    for d in range(6):
        ex, ey = target(d)
        mx, my = X0 + (ex - X0) / 2, Y0 + (ey - Y0) / 2     # posizione al passo 32
        for s in (0, 1):
            d2 = (d + 1) % 6 if s == 0 else (d + 5) % 6
            fx, fy = target(d2)
            vx.append((fx - mx) * 256 / 32)
            vy.append((fy - my) * 256 / 32)
            tc.append(d2)
    for v in range(18):
        # canna del cannone (8 direzioni) verso il bersaglio iniziale
        d = v if v < 6 else (v - 6) // 2
        a = CITY_ANGLES[d]
        aim.append(round(a / 45) % 8)
    return vx, vy, tc, aim


def data(name, vals, per=16):
    lines = [f"   data {name}"]
    for i in range(0, len(vals), per):
        chunk = ", ".join(str(v) for v in vals[i:i + per])
        lines.append("   " + chunk + ("," if i + per < len(vals) else ""))
    lines.append("end")
    return "\n".join(lines)


def main(bank):
    if bank == "bank2":
        p = pieces()
        print("   ; pezzetti delle 6 citta' (8 per citta', dal piu' alto; 255 = vuoto)")
        print(data("pcol", [c for city in p for c, _ in city]))
        print(data("prow", [r for city in p for _, r in city]))
        return
    vx, vy, tc, aim = velocities()
    print("   ; velocita' 8.8 dei proiettili: 0-5 verso la citta', 6-17 deviati")
    print(data("vxh", [s16(v)[0] for v in vx], 18))
    print(data("vxl", [s16(v)[1] for v in vx], 18))
    print(data("vyh", [s16(v)[0] for v in vy], 18))
    print(data("vyl", [s16(v)[1] for v in vy], 18))
    print("   ; citta' colpita alla fine del volo e direzione della canna (0-7)")
    print(data("tcity", tc, 18))
    print(data("aim8", aim, 18))
    shx, shy = [], []
    for k in range(64):
        t = 2 * math.pi * k / 64
        cx, cy = X0 + SX * math.cos(t), Y0 + SY * math.sin(t)
        shx.append(round(cx - 4))
        shy.append(round(cy + 4))
    print("   ; orbita del difensore: 64 posizioni (angolo/4)")
    print(data("shx", shx))
    print(data("shy", shy))
    pad = [min(255, round(v * 256 / (PADDLE_MAX + 1))) for v in range(80)]
    print(f"   ; paddle (0-{PADDLE_MAX}) -> angolo del difensore: tutta la corsa = un giro")
    print(data("padangle", pad))


if __name__ == "__main__":
    import sys
    main(sys.argv[1] if len(sys.argv) > 1 else "bank1")
