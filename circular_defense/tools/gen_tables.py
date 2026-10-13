"""Genera le tabelle di Circular Defense.bas (anello della citta', orbita
dello scudo, velocita' dei proiettili).

Coordinate dei missili (come le usa batari Basic):
  colonna del playfield c  -> pixel x = 4*c + 18 .. 4*c + 21
  riga del playfield r     -> y = 8*r .. 8*r + 7 (centro 8*r + 4)
Centro dello schermo: x = 82 (tra le colonne 15 e 16), y = 44 (riga 5).

Uso:  python3 gen_tables.py   -> stampa i blocchi "data" da incollare nel BAS
"""
import math

X0, Y0 = 82, 44
RX, RY = 56, 40          # anello della citta' (pixel x, unita' y)
SX, SY = 28, 20          # orbita dello scudo
STEPS = 64               # passi di un proiettile dal centro all'anello


def blocks():
    out = []
    for d in range(12):
        t = math.radians(d * 30)
        ex, ey = X0 + RX * math.cos(t), Y0 + RY * math.sin(t)
        c = round((ex - 22) / 4)          # colonna sinistra del blocco (2 pixel)
        r = min(10, max(0, round((ey - 4) / 8)))
        out.append((c, r))
    return out


def s16(v):
    v = round(v) & 0xFFFF
    return v >> 8, v & 0xFF


def main():
    b = blocks()
    print("   ; anello della citta': 12 blocchi (2 pixel del playfield), d*30 gradi")
    print("   data blkcol\n   " + ", ".join(str(c) for c, _ in b) + "\nend")
    print("   data blkrow\n   " + ", ".join(str(r) for _, r in b) + "\nend")
    vxh, vxl, vyh, vyl = [], [], [], []
    for c, r in b:
        ex, ey = 4 * c + 22, 8 * r + 4           # centro del blocco
        hx, lx = s16((ex - X0) * 256 / STEPS)
        hy, ly = s16((ey - Y0) * 256 / STEPS)
        vxh.append(hx); vxl.append(lx); vyh.append(hy); vyl.append(ly)
    print(f"   ; velocita' 8.8 (complemento a due): dal centro al blocco in {STEPS} passi")
    for name, t in (("vxh", vxh), ("vxl", vxl), ("vyh", vyh), ("vyl", vyl)):
        print(f"   data {name}\n   " + ", ".join(map(str, t)) + "\nend")
    shx, shy = [], []
    for k in range(64):
        t = 2 * math.pi * k / 64
        cx, cy = X0 + SX * math.cos(t), Y0 + SY * math.sin(t)
        shx.append(round(cx - 4))      # player0x: sprite di 8 pixel centrato
        shy.append(round(cy + 4))      # player0y: sprite di 8 righe centrato
    print("   ; orbita dello scudo: 64 posizioni (angolo/4)")
    for name, t in (("shx", shx), ("shy", shy)):
        print(f"   data {name}")
        for i in range(0, 64, 16):
            print("   " + ", ".join(map(str, t[i:i + 16])) + ("," if i < 48 else ""))
        print("end")


if __name__ == "__main__":
    main()
