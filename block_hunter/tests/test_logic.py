"""Test della logica di BLOCK HUNTER 2600 nell'emulatore minimo (tests/sim.py).

Uso: python3 tests/test_logic.py ROM SYM
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sim import Sim  # noqa: E402

FLOOR, COVER, PIECE, HOLE, ROCK, SAND, DOOR, ROLL, WALL = 0, 1, 2, 3, 7, 9, 10, 11, 15
UP, DOWN, LEFT, RIGHT = 0xE0, 0xD0, 0xB0, 0x70
ROM, SYM = sys.argv[1], sys.argv[2]
results = []


def check(name, ok, info=""):
    results.append((name, ok))
    print(("ok   " if ok else "FAIL ") + name + ("" if ok else f"   {info}"))


class Game:
    def __init__(self, level=0):
        self.s = Sim(ROM, SYM)
        self.s.frames(5)
        self.s.mem.sc[0] = level
        self.s.press(6, fire=True)
        self.s.frames(75)

    def __getitem__(self, k):
        return self.s[k]

    def __setitem__(self, k, v):
        self.s[k] = v

    def frames(self, n=1, joy=0xF0, fire=False, safe=False):
        for _ in range(n):
            self.s.mem.joy, self.s.mem.fire = joy, fire
            if safe:
                self.s["invul"] = 50
            self.s.frames(1)
        self.s.mem.joy, self.s.mem.fire = 0xF0, False

    def pat(self, tx, ty):
        k, p = tx >> 2, tx & 3
        if k % 2 == 0:
            ml, mr = 1 << (7 - 2 * p), 1 << (6 - 2 * p)
        else:
            ml, mr = 1 << (2 * p), 1 << (2 * p + 1)
        top, bot = self.s.sc(0x28 + 8 * ty + k), self.s.sc(0x28 + 8 * ty + 4 + k)
        return (8 if top & ml else 0) | (4 if top & mr else 0) | (2 if bot & ml else 0) | (1 if bot & mr else 0)

    def put(self, tx, ty):
        self.s["PX"], self.s["PY"] = 8 * tx, 8 * ty

    def score(self):
        return int("".join(f"{self.s[0x93 + i]:02x}" for i in range(3)))

    def no_enemies(self):
        for k in ("et", "var11", "est", "var17"):
            self.s[k] = 0
        self.s["enq"] = 9

    def lines(self):
        return self.s.mem.lines


def tile_of(g):
    return (g["PX"] + 4) // 8, (g["PY"] + 4) // 8


# ---------------------------------------------------------------- livello 1
g = Game(0)
check("parte il livello 1", g["phase"] == 0 and g["level"] == 0)
check("mappa: bordo e sabbia", g.pat(0, 0) == WALL and g.pat(6, 1) == SAND and g.pat(9, 3) == HOLE)
check("partenza su S", (g["PX"], g["PY"]) == (8, 8))
check("frame da 316 linee costanti", set(g.lines()[-60:]) == {316}, set(g.lines()[-60:]))
g.no_enemies()
g.frames(40, RIGHT)
check("cammina a destra un pixel per frame", g["PX"] in range(44, 50), g["PX"])
g.put(1, 1)
g.frames(20, UP)
check("il muro ferma (riquadro di 6 pixel: lo sprite tocca il muro)", g["PY"] == 7, g["PY"])
g.put(5, 1)
g.frames(16, RIGHT)
check("la sabbia rallenta", g["PX"] < 40 + 12 and g["slow"] > 0, (g["PX"], g["slow"]))
g["slow"] = 0
s0 = g.score()
g.put(13, 1)
g.frames(3)
check("gemma raccolta (+50, oggetto successivo)", g.score() == s0 + 50 and g["itemi"] == 1, (g.score(), g["itemi"]))
lives = g["nlives"]
g["invul"] = 0
g.put(9, 3)
g.frames(3)
check("buca: una vita in meno e di nuovo alla partenza", g["nlives"] == lives - 1 and tile_of(g) == (1, 1),
      (g["nlives"], tile_of(g)))
# salto sopra la buca (9,4) da (8,4)
g["invul"] = 0
g.put(8, 4)
g.frames(2)
g.frames(2, RIGHT, True)
g.frames(14)
check("salto di 2 caselle sopra la buca", tile_of(g) == (10, 4) and g["nlives"] == lives - 1, (tile_of(g), g["nlives"]))
# il salto non passa i muri
g.put(1, 2)
g.frames(2)
g.frames(2, LEFT, True)
g.frames(14)
check("niente salto contro il bordo", tile_of(g) == (1, 2), tile_of(g))
# dinamite sulla roccia (12,3) da (10,3)
dyn = g["dyn"]
g.put(10, 3)
g["pdir"] = 2
g.frames(2)
g.frames(2, fire=True)
check("dinamite lanciata (una in meno)", g["dyn"] == dyn - 1 and g["flags"] & 4, (g["dyn"], g["flags"]))
s0 = g.score()
g.frames(20)
check("la roccia salta (+10)", g.pat(12, 3) == FLOOR and g.score() == s0 + 10, (g.pat(12, 3), g.score()))
# rocce che cadono
g.put(1, 9)
fell = None
for k in range(400):
    g.frames(1, safe=True)
    if g["rockw"]:
        p = g["rockp"]
        fell = (p & 15, p >> 4)
        break
check("una roccia sta per cadere", fell is not None)
if fell:
    x, y = fell
    ok = all(g.pat(x + dx, y + dy) in (FLOOR, COVER) for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)))
    check("su una casella libera con le 4 vicine libere", ok)
    g.frames(60, safe=True)
    check("la roccia resta li'", g.pat(x, y) == ROCK, g.pat(x, y))
    # roccia sul giocatore
    g.frames(1)
    g["invul"] = 0
    g["rockw"], g["rockp"] = 2, y * 16 + x - 1 if g.pat(x - 1, y) == FLOOR else y * 16 + x + 1
    tx = g["rockp"] & 15
    g.put(tx, y)
    lives = g["nlives"]
    g.frames(4)
    check("la roccia che cade sul giocatore toglie una vita", g["nlives"] == lives - 1, g["nlives"])

# ---------------------------------------------------------------- uscita
g = Game(0)
g.no_enemies()
g["lrock"] = 0
for i in range(5):
    p = g["itempos"]
    g.put(p & 15, p >> 4)
    g.frames(3, safe=True)
check("dopo l'ultimo oggetto c'e' l'uscita", g["itemt"] == 5 and g["flags"] & 2, (g["itemt"], g["flags"]))
p = g["itempos"]
g.put(p & 15, p >> 4)
g.frames(3)
check("uscita: livello finito", g["phase"] == 4)
g.frames(110)
check("si passa al livello 2", g["level"] == 1 and g["phase"] in (1, 2, 0), (g["level"], g["phase"]))
g.frames(80)
check("livello 2: la porta", g.pat(7, 4) == DOOR, g.pat(7, 4))

# ---------------------------------------------------------------- porta e chiave
g = Game(1)
g.no_enemies()
g["lrock"] = 0
g.put(6, 4)
g.frames(10, RIGHT)
check("la porta chiusa ferma", g["PX"] <= 8 * 6 + 1 and g.pat(7, 4) == DOOR, (g["PX"], g.pat(7, 4)))
for i in range(3):
    p = g["itempos"]
    g.put(p & 15, p >> 4)
    g.frames(3, safe=True)
check("presa la chiave", g["flags"] & 1, g["flags"])
g.put(6, 4)
g.frames(16, RIGHT)
check("con la chiave la porta si apre", g.pat(7, 4) == FLOOR and g["PX"] > 8 * 6 + 4, (g.pat(7, 4), g["PX"]))

# ---------------------------------------------------------------- nemici
g = Game(1)        # ragno
g["lrock"] = 0
g.frames(5)
check("il ragno entra", g["et"] & 0x83 == 0x81, hex(g["et"]))
d0 = abs(g["ex"] - g["PX"]) + abs(g["ey"] - g["PY"])
g.put(10, 8)
g.frames(2)
d0 = abs(g["ex"] - g["PX"]) + abs(g["ey"] - g["PY"])
g.frames(60, safe=True)
d1 = abs(g["ex"] - g["PX"]) + abs(g["ey"] - g["PY"])
check("il ragno insegue", d1 < d0, (d0, d1))
lives = g["nlives"]
s0 = g.score()
g["invul"] = 0
g.s.mem.cxppmm = 0x80
g.s["mux"] = 0
g.frames(1)
g.s.mem.cxppmm = 0
check("il ragno morde: -1 vita", g["nlives"] == lives - 1, g["nlives"])
# dinamite sul ragno
g.frames(5)
g["flags"] |= 4
g["DX"], g["DY"], g["dynl"], g["dynd"] = 33, 49, 20, 2
g.s.mem.cxm0p = 0x80
g.s["mux"] = 0
s0 = g.score()
g.frames(1)
g.s.mem.cxm0p = 0
check("dinamite sul ragno: +20, muore", g.score() == s0 + 20 and not g["et"] & 0x80, (g.score(), hex(g["et"])))

g = Game(2)        # serpente
g.frames(5)
check("il serpente entra", g["et"] & 0x83 == 0x82, hex(g["et"]))
ok = True
for k in range(300):
    g.frames(1, safe=True)
    if not (8 <= g["ex"] <= 112 and 8 <= g["ey"] <= 72):
        ok = False
        break
    x, y = g["ex"], g["ey"]
    for px, py in ((x, y), (x + 7, y), (x, y + 7), (x + 7, y + 7)):
        if g.pat(px // 8, py // 8) == WALL:
            ok = False
check("il serpente resta nella mappa e non entra nei muri", ok, (g["ex"], g["ey"]))
g["invul"] = 0
g.s["mux"] = 0
g.s.mem.cxppmm = 0x80
lives = g["nlives"]
g.frames(1)
g.s.mem.cxppmm = 0
g.frames(2)
check("morso del serpente: -1 vita e il livello ricomincia", g["nlives"] == lives - 1 and g["phase"] in (1, 6),
      (g["nlives"], g["phase"]))

g = Game(0)        # pipistrello: ruba la gemma
g["lrock"] = 0
p = g["itempos"]
g.put(p & 15, p >> 4)
g.frames(3, safe=True)
g.frames(70)
g["invul"] = 0
lives = g["nlives"]
g.s["mux"] = 0
g.s["et"] = 0x80
g.s.mem.cxppmm = 0x80
g.frames(1)
g.s.mem.cxppmm = 0
check("il pipistrello ruba la gemma (niente vita persa)", g["itemi"] == 0 and g["nlives"] == lives,
      (g["itemi"], g["nlives"]))

# ---------------------------------------------------------------- massi
g = Game(5)
g.no_enemies()
g["lrock"] = 0
g.put(1, 1)
seen = set()
for k in range(800):
    g.frames(1, safe=True)
    for i in range(4):
        if g[f"var{20 + i}"]:
            seen.add(g[f"var{24 + i}"] & 4)
check("arrivano i massi", 0 in seen, seen)
check("i massi si spaccano in pezzi", 4 in seen, seen)

# ---------------------------------------------------------------- fine
g = Game(0)
g.no_enemies()
g["lrock"] = 0
g["nlives"] = 1
g["invul"] = 0
g.put(9, 3)
g.frames(3)
check("ultima vita: partita finita", g["phase"] == 3)
g.frames(160)
check("poi il titolo", g["phase"] == 0 and g["level"] == 0)

bad = [n for n, ok in results if not ok]
print(f"{len(results) - len(bad)}/{len(results)} ok")
sys.exit(1 if bad else 0)
