"""Banco di prova di BLOCK HUNTER 2600 in Stella (xvfb + xdotool), sul
modello di snack_and_roll/tests/snr.py: legge e modifica la RAM (anche
quella della Superchip, dove sta il playfield) dagli stati salvati."""
import os
import subprocess
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "snack_and_roll", "tests"))
import snr  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
A = {c: 0xD4 + i for i, c in enumerate("abcdefghijklmnopqrstuvwxyz")}
NAMES = {"level": "a", "nlives": "b", "dyn": "c", "frame": "d", "pdir": "e", "jumpt": "f", "jdir": "g",
         "invul": "h", "slow": "i", "planks": "j", "flags": "k", "itemi": "l", "itemt": "m", "dynd": "n",
         "dynl": "o", "sfxid": "p", "sfxt": "q", "rockt": "r", "rockw": "s", "rockp": "t", "bldt": "u",
         "bldm": "v", "mux": "w", "enq": "x", "phase": "y", "rng": "z"}
V = {k: A[c] for k, c in NAMES.items()}
VARS = ["PX", "PY", "DX", "DY", "lvlo", "lvhi", "ex", "ex1", "ey", "ey1", "et", "et1", "etm", "etm1", "ect",
        "ect1", "est", "est1", "espawn", "espawn1", "bpos", "bpos1", "bpos2", "bpos3", "binfo", "binfo1",
        "binfo2", "binfo3", "lflags", "lrock", "lbside", "lbevery", "startpos", "exitpos", "nen", "nitems",
        "lbg", "itempos", "phaset", "expl", "lightt"]
for i, n in enumerate(VARS):
    V[n] = 0xA4 + i
PLAYER0X, PLAYER0Y, BALLX, BALLY = 0x80, 0x85, 0x84, 0x89
SCORE = 0x93
PFSCORE1, PFSCORE2 = 0xF2, 0xF3

# motivi delle caselle (vedi get_pat)
FLOOR, COVER, PIECE, HOLE, ROCK, SAND, DOOR, ROLL, WALL = 0, 1, 2, 3, 7, 9, 10, 11, 15


def title_pf():
    """l'immagine del titolo (title.inc), per trovare la RAM della Superchip"""
    out = []
    for line in open(os.path.join(ROOT, "title.inc")):
        if line.startswith(" .byte"):
            out += [int(v.strip()[1:], 16) for v in line.split(None, 1)[1].split(",")]
    return bytes(out)


class Ram(snr.Ram):
    def __init__(self, data, sc):
        super().__init__(data)
        self.sc = sc

    def v(self, name):
        return self[V[name]]

    def r(self, n):
        """byte n della Superchip in lettura (r000 ...)"""
        return self.sc[n]

    def pf_byte(self, off):
        return self.sc[0x28 + off]

    def pat(self, tx, ty):
        """motivo della casella (bit 3 alto-sinistra ... bit 0 basso-destra)"""
        k, p = tx >> 2, tx & 3
        if k % 2 == 0:
            ml, mr = 1 << (7 - 2 * p), 1 << (6 - 2 * p)
        else:
            ml, mr = 1 << (2 * p), 1 << (2 * p + 1)
        top, bot = self.pf_byte(8 * ty + k), self.pf_byte(8 * ty + 4 + k)
        return (8 if top & ml else 0) | (4 if top & mr else 0) | (2 if bot & ml else 0) | (1 if bot & mr else 0)

    def tiles(self):
        ch = {FLOOR: ".", WALL: "#", HOLE: "o", SAND: ":", ROCK: "*", DOOR: "D", ROLL: "@", PIECE: ",", COVER: "_"}
        return ["".join(ch.get(self.pat(x, y), "?") for x in range(16)) for y in range(11)]

    def score(self):
        return int("".join(f"{self[SCORE + i]:02x}" for i in range(3)))


class Stella(snr.Stella):
    def save(self):
        old = os.path.getmtime(self.state) if os.path.exists(self.state) else 0
        self.tap("F9", 0.05)
        for _ in range(100):
            snr.time.sleep(0.03)
            if os.path.exists(self.state) and os.path.getmtime(self.state) != old:
                snr.time.sleep(0.05)
                break
        data = open(self.state, "rb").read()
        if self.ram_off is None:
            self.ram_off, sc = self._find(data)
            # la Superchip e' verso la fine dello stato, che non ha sempre la
            # stessa lunghezza: la si conta dalla fine
            self.sc_end = len(data) - sc
        self.sc_off = len(data) - self.sc_end
        return Ram(bytes(data[self.ram_off:self.ram_off + 128]), bytes(data[self.sc_off:self.sc_off + 128]))

    def _find(self, data):
        # serve il titolo sullo schermo: l'immagine e' nella Superchip da $28
        sig = title_pf()[8:48]
        i = data.find(sig)
        if i < 0:
            raise RuntimeError("Superchip non trovata (serve il titolo)")
        sc = i - 0x28 - 8
        # RAM: player0y, player1y, bally a 200 nel titolo
        for j in range(len(data) - 128):
            if data[j + 5] == 200 and data[j + 6] == 200 and data[j + 9] == 200 and data[j + 0x72] == 0:
                return j, sc
        raise RuntimeError("RAM non trovata")

    def poke(self, values, sc=None):
        data = bytearray(open(self.state, "rb").read())
        self.sc_off = len(data) - self.sc_end
        for addr, val in values.items():
            data[self.ram_off + addr - 0x80] = val & 0xFF
        for off, val in (sc or {}).items():
            data[self.sc_off + off] = val & 0xFF
        open(self.state, "wb").write(data)
        self.tap("F11", 0.05)
        snr.time.sleep(0.15)

    def grab(self, path):
        wid = subprocess.run(["xdotool", "search", "--pid", str(self.p.pid)], capture_output=True,
                             text=True).stdout.split()[-1]
        subprocess.run(["import", "-window", wid, path])
