"""Banco di prova di OXYGEN 2600 in Stella (xvfb + xdotool), sul modello di
snack_and_roll/tests/snr.py: legge e modifica la RAM dagli stati salvati."""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "snack_and_roll", "tests"))
import snr  # noqa: E402

A = {c: 0xD4 + i for i, c in enumerate("abcdefghijklmnopqrstuvwxyz")}
V = {
    "level": A["a"], "room": A["b"], "frame": A["c"], "o2": A["d"], "o2tick": A["e"], "flags": A["f"],
    "dir": A["g"], "shotLife": A["h"], "ex0": A["i"], "ex1": A["j"], "ey0": A["k"], "ey1": A["l"],
    "einfo0": A["m"], "einfo1": A["n"], "bulletDir": A["o"], "shootTimer": A["p"], "mux": A["q"],
    "dead": A["r"], "base": A["s"], "baseInfo": A["t"], "canCool": A["u"], "sfxTime": A["v"],
    "sfxId": A["w"], "diff": A["x"], "hitCool": A["y"], "ball": A["z"],
}
PLAYER0X, PLAYER1X, MISSILE0X, MISSILE1X, BALLX = 0x80, 0x81, 0x82, 0x83, 0x84
PLAYER0Y, PLAYER1Y, MISSILE0Y, MISSILE1Y, BALLY = 0x85, 0x86, 0x91, 0x88, 0x89
PLAYFIELD = 0xA4
PFSCORE1, PFSCORE2 = 0xF2, 0xF3

TITLE = [
    "................................",
    ".XXXX.X..X.X..X.XXXX.XXXX.X..X..",
    ".X..X.X..X.X..X.X....X....XX.X..",
]


def pf_bytes(rows):
    out = []
    for row in rows:
        for k in range(4):
            bits = row[k * 8:(k + 1) * 8]
            v = 0
            for i, ch in enumerate(bits):
                if ch == "X":
                    v |= (1 << (7 - i)) if k % 2 == 0 else (1 << i)
            out.append(v)
    return bytes(out)


class Ram(snr.Ram):
    def v(self, name):
        return self[V[name]]


class Stella(snr.Stella):
    def save(self):
        r = super().save()
        return Ram(bytes(r.d))

    def _find_ram(self, data):
        sig = pf_bytes(TITLE)
        i = data.find(sig)
        while i >= 0:
            off = i - (PLAYFIELD - 0x80)
            if off >= 0:
                return off
            i = data.find(sig, i + 1)
        raise RuntimeError("RAM non trovata (serve il titolo sullo schermo)")


def _flag(self, bit):
    return (self[V["flags"]] >> bit) & 1


Ram.flag = _flag


def grab(s, path):
    """screenshot della sola finestra di Stella."""
    import subprocess
    wid = subprocess.run(["xdotool", "search", "--pid", str(s.p.pid)], capture_output=True, text=True).stdout.split()[-1]
    subprocess.run(["import", "-window", wid, path])
