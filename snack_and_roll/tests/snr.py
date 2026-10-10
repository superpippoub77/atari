"""Banco di prova per la ROM Atari di Snack 'n' Roll (Stella + xdotool).

Legge la RAM dai salvataggi di stato di Stella (F9) e la puo' modificare
ricaricando lo stato (F11). Va eseguito dentro xvfb-run.
"""
import os
import subprocess
import tempfile
import time

# cartella di lavoro di Stella (configurazione e stati salvati)
SP = os.environ.get("SNR_STELLA_HOME", os.path.join(tempfile.gettempdir(), "snr_stella"))

# indirizzi RAM (dal file .sym di batari Basic)
A = {c: 0xD4 + i for i, c in enumerate("abcdefghijklmnopqrstuvwxyz")}
PLAYER0X, PLAYER1X, MISSILE0X, MISSILE1X, BALLX = 0x80, 0x81, 0x82, 0x83, 0x84
PLAYER0Y, PLAYER1Y, MISSILE0Y, MISSILE1Y, BALLY = 0x85, 0x86, 0x91, 0x88, 0x89
PLAYFIELD = 0xA4
SCORE = 0x93
PFSCORE1, PFSCORE2 = 0xF2, 0xF3

V = {
    "mouthIndex": A["a"], "level": A["b"], "frame": A["c"], "seconds": A["d"],
    "choco_bits": A["e"], "mouth0x": A["f"], "speed": A["g"], "mouth0y": A["h"],
    "sugarIndex": A["i"], "flags": A["k"], "mouth1x": A["l"], "music": A["m"],
    "mouth1y": A["o"], "dir": A["p"], "prevSugarBit": A["q"], "pushCol": A["s"],
    "choco_count": A["t"], "ballx_var": A["u"], "hitCooldown": A["v"], "hasKey": A["z"],
}


class Ram:
    def __init__(self, data):
        self.d = bytearray(data)

    def __getitem__(self, addr):
        return self.d[addr - 0x80]

    def v(self, name):
        return self[V[name]]

    def flag(self, bit):
        return (self[V["flags"]] >> bit) & 1

    def pf(self, col, row):
        """pfread come in batari Basic (righe da 4 byte, byte 1 e 3 invertiti)."""
        idx = row * 4 + col // 8
        if not 0 <= idx < 48:
            return 0
        b = self[PLAYFIELD + idx]
        bit = col & 7
        if (col // 8) % 2 == 0:
            return (b >> (7 - bit)) & 1
        return (b >> bit) & 1

    def pf_rows(self):
        return ["".join("X" if self.pf(c, r) else "." for c in range(32)) for r in range(11)]

    def score(self):
        return int("".join("%02x" % self[SCORE + i] for i in range(3)))


class Stella:
    def __init__(self, rom, tag="t"):
        self.home = f"{SP}/stellahome_{tag}"
        os.makedirs(self.home, exist_ok=True)
        self.rom = rom
        self.name = os.path.splitext(os.path.basename(rom))[0]
        self.state = f"{self.home}/.config/stella/state/{self.name}.st0"
        self.ram_off = None
        env = dict(os.environ, HOME=self.home)
        self.p = subprocess.Popen(
            ["stella", "-fullscreen", "0", "-tia.zoom", "2", "-sound", "0", "-uimessages", "0",
             "-confirmexit", "0", rom],
            env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        # aspetta che la finestra esista e che F9 produca davvero uno stato
        for _ in range(120):
            time.sleep(0.5)
            wid = subprocess.run(["xdotool", "search", "--pid", str(self.p.pid)],
                                 capture_output=True, text=True).stdout.split()
            if not wid:
                continue
            subprocess.run(["xdotool", "windowfocus", wid[-1]], capture_output=True)
            self.tap("F9", 0.05)
            time.sleep(0.4)
            if os.path.exists(self.state):
                break
        else:
            raise RuntimeError("Stella non risponde")
        time.sleep(0.5)

    # --- input ---
    def down(self, *keys):
        subprocess.run(["xdotool", "keydown", *keys])

    def up(self, *keys):
        subprocess.run(["xdotool", "keyup", *keys])

    def tap(self, key, hold=0.12):
        self.down(key)
        time.sleep(hold)
        self.up(key)

    def hold(self, keys, seconds):
        self.down(*keys)
        time.sleep(seconds)
        self.up(*keys)

    def wait(self, seconds):
        time.sleep(seconds)

    # --- RAM ---
    def save(self):
        old = os.path.getmtime(self.state) if os.path.exists(self.state) else 0
        self.tap("F9", 0.05)
        for _ in range(100):
            time.sleep(0.03)
            if os.path.exists(self.state) and os.path.getmtime(self.state) != old:
                time.sleep(0.05)
                break
        data = open(self.state, "rb").read()
        if self.ram_off is None:
            self.ram_off = self._find_ram(data)
        return Ram(data[self.ram_off:self.ram_off + 128])

    def _find_ram(self, data):
        # pfscore2 = %10101010 all'avvio; il resto lo conferma il titolo
        for i in range(len(data) - 128):
            if data[i + 0x73] == 0xAA and data[i + 0x72] in (0xFF, 0xFE, 0xFC):
                return i
        raise RuntimeError("RAM non trovata nello stato")

    def poke(self, values):
        """Scrive {indirizzo: valore} nella RAM dello stato e lo ricarica."""
        data = bytearray(open(self.state, "rb").read())
        for addr, val in values.items():
            data[self.ram_off + addr - 0x80] = val & 0xFF
        open(self.state, "wb").write(data)
        self.tap("F11", 0.05)
        time.sleep(0.15)

    def shot(self, path):
        subprocess.run(["import", "-window", "root", path])

    def close(self):
        self.p.kill()
        self.p.wait()


def _snapshot(self):
    return bytearray(open(self.state, "rb").read())


def _restore(self, base, values):
    data = bytearray(base)
    for addr, val in values.items():
        data[self.ram_off + addr - 0x80] = val & 0xFF
    open(self.state, "wb").write(data)
    self.tap("F11", 0.05)
    time.sleep(0.15)


Stella.snapshot = _snapshot
Stella.restore = _restore
