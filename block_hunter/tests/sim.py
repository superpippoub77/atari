"""Emulatore minimo della cartuccia F8SC (8K + Superchip) con py65: CPU,
RAM, RAM della Superchip, timer RIOT, WSYNC, VSYNC, levetta e pulsante.
Niente grafica: serve per i test veloci della logica di BLOCK HUNTER.

Richiede py65 (pip install py65).
"""
from py65.devices.mpu6502 import MPU as _MPU


class MPU(_MPU):
    """6502 con gli opcode illegali usati dal kernel di batari Basic (dcp, lax, sbx)"""
    def _dcp(self, addr):
        a = addr()
        v = (self.ByteAt(a) - 1) & 255
        self.memory[a] = v
        self.opCMPR(lambda: a, self.a)

    def _lax(self, addr):
        v = self.ByteAt(addr())
        self.a = self.x = v
        self.FlagsNZ(v)

    def i_c7(self):
        self._dcp(self.ZeroPageAddr)
        self.pc += 1

    def i_cf(self):
        self._dcp(self.AbsoluteAddr)
        self.pc += 2

    def i_a7(self):
        self._lax(self.ZeroPageAddr)
        self.pc += 1

    def i_af(self):
        self._lax(self.AbsoluteAddr)
        self.pc += 2

    def i_b3(self):
        self._lax(self.IndirectYAddr)
        self.pc += 1

    def i_cb(self):
        v = self.ByteAt(self.pc)
        t = (self.a & self.x) - v
        self.p &= ~(self.CARRY | self.ZERO | self.NEGATIVE)
        if t >= 0:
            self.p |= self.CARRY
        t &= 255
        self.x = t
        if t == 0:
            self.p |= self.ZERO
        self.p |= t & self.NEGATIVE
        self.pc += 1


MPU.instruct = list(_MPU.instruct)
MPU.cycletime = list(_MPU.cycletime)
MPU.extracycles = list(_MPU.extracycles)
for _op, _f, _c in ((0xC7, MPU.i_c7, 5), (0xCF, MPU.i_cf, 6), (0xA7, MPU.i_a7, 3), (0xAF, MPU.i_af, 4),
                    (0xB3, MPU.i_b3, 5), (0xCB, MPU.i_cb, 2)):
    MPU.instruct[_op] = _f
    MPU.cycletime[_op] = _c
    MPU.extracycles[_op] = 0


class Mem:
    def __init__(self, rom):
        self.rom = rom
        self.ram = bytearray(128)
        self.sc = bytearray(128)
        self.bank = 1
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
        self.joy = 0xF0        # SWCHA (bit a 0 = premuto: 7 destra, 6 sinistra, 5 giu', 4 su)
        self.cxppmm = 0
        self.cxm0p = 0
        self.lines = []        # linee per frame

    def intim(self):
        el = self.cyc - self.timer_set
        ticks = el >> self.timer_shift
        if ticks <= self.timer_val:
            return (self.timer_val - ticks) & 255
        over = el - ((self.timer_val + 1) << self.timer_shift)
        return (-1 - over) & 255

    def __getitem__(self, a):
        a &= 0x1FFF
        if a & 0x1000:
            off = a & 0xFFF
            if off in (0xFF8, 0xFF9):
                self.bank = off - 0xFF8
            if 0x80 <= off < 0x100:
                return self.sc[off - 0x80]
            return self.rom[self.bank * 4096 + off]
        if a & 0x80 and not a & 0x200:
            return self.ram[a & 0x7F]
        if a & 0x280 == 0x280:
            r = a & 0x7
            if r == 4:
                return self.intim()
            if r == 0:
                return self.joy | 0x0F
            if r == 2:
                v = 0xFF
                if self.select:
                    v &= ~2
                if self.reset:
                    v &= ~1
                return v
            return 0
        r = a & 0x0F
        if r == 0x0C:
            return 0x00 if self.fire else 0x80
        if r == 0x07:
            return self.cxppmm
        if r == 0x00:
            return self.cxm0p
        return 0x80 if r == 0x0D else 0

    def __setitem__(self, a, v):
        a &= 0x1FFF
        if a & 0x1000:
            off = a & 0xFFF
            if off in (0xFF8, 0xFF9):
                self.bank = off - 0xFF8
            if off < 0x80:
                self.sc[off] = v
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
        if r == 0x02:
            self.wsync = True
        elif r == 0x00:
            on = bool(v & 2)
            if on and not self.vsync_on:
                if self.frame_starts:
                    self.lines.append(round((self.cyc - self.frame_starts[-1]) / 76))
                self.frame_starts.append(self.cyc)
            self.vsync_on = on

    def __len__(self):
        return 0x10000


class Sim:
    def __init__(self, romfile, symfile):
        rom = open(romfile, "rb").read()
        self.sym = {}
        for ln in open(symfile):
            p = ln.split()
            if len(p) >= 2:
                try:
                    self.sym[p[0]] = int(p[1], 16)
                except ValueError:
                    pass
        self.mem = Mem(rom)
        self.cpu = MPU(memory=self.mem)
        self.cpu.pc = rom[4096 + 0xFFC] | rom[4096 + 0xFFD] << 8
        self.minsp = 255
        self.hook = None

    def frames(self, n=1):
        target = len(self.mem.frame_starts) + n
        m, cpu = self.mem, self.cpu
        steps = 0
        nf = len(m.frame_starts)
        while len(m.frame_starts) < target:
            c0 = cpu.processorCycles
            cpu.step()
            m.cyc += cpu.processorCycles - c0
            if m.wsync:
                m.wsync = False
                m.cyc = (m.cyc // 76 + 1) * 76
            if cpu.sp < self.minsp and len(m.frame_starts) > 3:
                self.minsp = cpu.sp
            if self.hook:
                self.hook(self)
            steps += 1
            if len(m.frame_starts) != nf:
                nf, steps = len(m.frame_starts), 0
            if steps > 60000:
                raise RuntimeError(f"frame troppo lungo, pc={cpu.pc:04x}")

    def addr(self, name):
        return self.sym[name] if isinstance(name, str) else name

    def __getitem__(self, name):
        return self.mem.ram[self.addr(name) & 0x7F]

    def __setitem__(self, name, v):
        self.mem.ram[self.addr(name) & 0x7F] = v & 255

    def sc(self, n):
        return self.mem.sc[n]

    def press(self, n=4, **keys):
        for k, v in keys.items():
            setattr(self.mem, k, v)
        self.frames(n)
        for k in keys:
            setattr(self.mem, k, False if k != "joy" else 0xF0)
