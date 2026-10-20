"""Emulatore minimo della cartuccia 8K F8 con py65 (CPU, RAM, timer RIOT, WSYNC, VSYNC, pulsante): per i test.

Richiede py65 (pip install py65).
"""
import sys
from py65.devices.mpu6502 import MPU

rom = None
banks = 2


class Mem:
    def __init__(self):
        self.ram = bytearray(128)
        self.bank = 0 if banks > 1 else 0
        self.cyc = 0
        self.timer_set = 0
        self.timer_val = 0
        self.timer_shift = 6
        self.wsync = False
        self.vsync_on = False
        self.frame_starts = []
        self.fire = False
        self.reset = False
        self.select = False
        self.vis = []

    def intim(self):
        el = self.cyc - self.timer_set
        ticks = el >> self.timer_shift
        if ticks <= self.timer_val:
            return (self.timer_val - ticks) & 255
        # dopo lo zero: un passo per ciclo
        over = el - ((self.timer_val + 1) << self.timer_shift)
        return (-1 - over) & 255

    def __getitem__(self, a):
        a &= 0x1FFF
        if a & 0x1000:
            if banks > 1 and a in (0x1FF8, 0x1FF9):
                self.bank = a - 0x1FF8
            return rom[self.bank * 4096 + (a & 0xFFF)]
        if a & 0x80 and not a & 0x200:
            return self.ram[a & 0x7F]
        if a & 0x280 == 0x280:
            r = a & 0x7
            if r == 4:
                return self.intim()
            if r == 0:
                return 0xFF       # SWCHA
            if r == 2:
                v = 0xFF
                if self.select:
                    v &= ~2
                if self.reset:
                    v &= ~1
                return v           # SWCHB
            return 0
        r = a & 0x0F
        if r == 0x0C:
            return 0x00 if self.fire else 0x80   # INPT4
        if r == 0x0D:
            return 0x80
        return 0

    def __setitem__(self, a, v):
        a &= 0x1FFF
        if a & 0x1000:
            if banks > 1 and a in (0x1FF8, 0x1FF9):
                self.bank = a - 0x1FF8
            return
        if a & 0x80 and not a & 0x200:
            self.ram[a & 0x7F] = v
            return
        if a & 0x280 == 0x280:
            r = a & 0x1F
            if r in (0x14, 0x15, 0x16, 0x17, 0x1C, 0x1D, 0x1E, 0x1F):
                self.timer_shift = {0: 0, 1: 3, 2: 6, 3: 10}[r & 3]
                self.timer_val = v
                self.timer_set = self.cyc
            return
        r = a & 0x3F
        if r == 0x02:          # WSYNC
            self.wsync = True
        elif r == 0x01:        # VBLANK
            if not v & 2:
                self.vis_start = self.cyc
            elif getattr(self, "vis_start", None) is not None:
                self.vis.append(round((self.cyc - self.vis_start) / 76, 1))
                self.vis_start = None
        elif r == 0x00:        # VSYNC
            on = bool(v & 2)
            if on and not self.vsync_on:
                self.frame_starts.append(self.cyc)
            self.vsync_on = on

    def __len__(self):
        return 0x10000




class Sim:
    def __init__(self, romfile, symfile):
        global rom
        rom = open(romfile, "rb").read()
        self.sym = {}
        for ln in open(symfile):
            p = ln.split()
            if len(p) >= 2 and p[0] != '---':
                try: self.sym[p[0]] = int(p[1], 16)
                except ValueError: pass
        self.mem = Mem()
        self.cpu = MPU(memory=self.mem)
        self.cpu.pc = rom[4096 + 0xFFC] | rom[4096 + 0xFFD] << 8
        self.mem.bank = 1
        self.minsp = 255
    def frames(self, n=1):
        target = len(self.mem.frame_starts) + n
        m, cpu = self.mem, self.cpu
        while len(m.frame_starts) < target:
            c0 = cpu.processorCycles
            cpu.step()
            m.cyc += cpu.processorCycles - c0
            if m.wsync:
                m.wsync = False
                m.cyc = (m.cyc // 76 + 1) * 76
            if len(m.frame_starts) > 3 and cpu.sp < self.minsp: self.minsp = cpu.sp
    def __getitem__(self, name):
        return self.mem.ram[(self.sym[name] if isinstance(name, str) else name) & 0x7F]
    def __setitem__(self, name, v):
        self.mem.ram[(self.sym[name] if isinstance(name, str) else name) & 0x7F] = v & 255
    def select(self, n=4):
        self.mem.select = True; self.frames(n); self.mem.select = False; self.frames(4)

    def tap(self, n=4):
        self.mem.fire = True; self.frames(n); self.mem.fire = False; self.frames(2)
