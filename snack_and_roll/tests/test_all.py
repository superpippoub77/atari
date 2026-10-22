"""Test completo della ROM Atari di Snack 'n' Roll, livello per livello.

Uso (serve Stella, xdotool, ImageMagick e xvfb-run):
  xvfb-run -a -s "-screen 0 800x600x24" python3 test_all.py . "../bin/Snack and Roll.bas.bin" /tmp/screenshot

Gioca una partita completa dal livello 1 alla vittoria pilotando i tasti:
raccoglie gli 8 zuccherini camminando lungo il percorso calcolato sul
playfield letto dalla RAM, spara alla bocca, prende il sacchetto. In piu'
controlla appoggi degli oggetti, gocce, luce, tempo, vite, muro
spingibile (livello 5), selezione del livello e game over.
"""
import sys
import time
from collections import deque

sys.path.insert(0, sys.argv[1])
from snr import *  # noqa

ROM = sys.argv[2]
OUT = sys.argv[3]
RESULTS = []

from model import OBJECTS, DESTRUCTIBLE_ROWS, missile_hit, sugar_cell, sugar_xy, destroy_closure  # noqa
import model  # noqa
SUGAR = [  # BAS: data sugar
    20, 61, 18, 34, 63, 49, 25, 23,
    43, 55, 33, 19, 36, 13, 17, 22,
    45, 57, 39, 27, 42, 21, 17, 15,
    54, 31, 43, 57, 53, 27, 17, 29,
    9, 15, 47, 43, 37, 41, 10, 13,
    57, 63, 51, 19, 53, 31, 25, 29,
]


def check(level, name, ok, detail=""):
    RESULTS.append((level, name, bool(ok), detail))
    print(("  ok   " if ok else "  FAIL ") + f"[L{level}] {name}" + (f"  ({detail})" if detail else ""), flush=True)
    return ok


# ---------------------------------------------------------------------
# modello: drop e muro come ostacoli, movimento identico al BAS
# ---------------------------------------------------------------------
MOUTH_SPEED = [12, 10, 9, 8, 8, 7]   # BAS: data mouthspeed (frame per passo)
FRAME_LIMIT = 47                     # BAS: const frame_limit (48 frame = 1 "secondo")
# effetti sonori (BAS: callmacro sfx N)
SFX = {"sparo": 1, "muro": 2, "scossa": 3, "blocco": 4, "zuccherino": 5, "bocca": 6, "potere": 7, "livello": 8}


def sfx_seen(s, seconds, first=None):
    """Effetti sonori ascoltati (valori di _sfxId) nei prossimi secondi."""
    seen = set()
    if first is not None:
        seen.add(first.v("sfxId"))
    t0 = time.time()
    while time.time() - t0 < seconds:
        seen.add(s.save().v("sfxId"))
        s.wait(0.05)
    seen.discard(0)
    return seen
LEVELS = len(OBJECTS)


def _push_sugars():
    out = {}
    for lv in range(1, LEVELS + 1):
        if not model.wall_cols(lv):
            continue
        reach0, union = model.push_reach(lv)
        vs = {v for v in SUGAR[(lv - 1) * 8:lv * 8]
              if not model.sugar_reachable(v, reach0) and model.sugar_reachable(v, union)}
        if vs:
            out[lv] = vs
    return out


PUSH_SUGARS = _push_sugars()   # {livello: zuccherini raggiungibili solo spingendo un muro}


def walls(ram):
    """Muri spingibili presenti (255 = nessuno): colonna, + 128 se sul piano."""
    if ram.v("level") == 7:      # Bocca Gigante: var44-var47 sono gli sputi
        return []
    return [c for c in (ram.v(n) for n in WALL_NAMES) if c != 255]


def moving(level):
    """livello con ostacoli che si muovono (gocce o presse)."""
    return bool(OBJECTS[level - 1][3])


def drop_cells(level):
    """celle di gocce e presse (dal modello: le presse a T hanno la testa larga)."""
    return model.drop_cells(level)


class Grid:
    def __init__(self, ram, level):
        self.level = level
        self.cells = {(c, r) for r in range(12) for c in range(32) if ram.pf(c, r)}
        # gocce e presse: conta solo dove sono in questo momento (si passa
        # aspettando che si spostino)
        self.cells |= model.wall_cells(walls(ram))

    def pf(self, c, r):
        if c >= 32:  # come pfread: sconfina nella riga successiva
            c, r = c - 32, r + 1
        return (c, r) in self.cells

    def moves(self, x, y):
        pf = self.pf
        out = []
        # su
        if y > 8:
            t5 = ((x - 10) & 255) // 4
            t6 = ((y - 5) & 255) // 8
            t4 = ((x - 17) & 255) // 4
            t3 = (t5 - 1) & 255
            if not ((t5 < 31 and pf(t5, t6)) or (t4 < 31 and pf(t4, t6)) or (t3 < 31 and pf(t3, t6))):
                out.append((x, y - 1))
        # giu'
        if y < 88:
            t5 = ((x - 10) & 255) // 4
            t6 = (y & 255) // 8
            t4 = ((x - 17) & 255) // 4
            t3 = (t5 - 1) & 255
            if not ((t5 < 31 and pf(t5, t6)) or (t4 < 31 and pf(t4, t6)) or (t3 < 31 and pf(t3, t6))):
                out.append((x, y + 1))
        # sinistra
        if x > 10:
            t5 = ((y - 1) & 255) // 8
            t6 = ((x - 18) & 255) // 4
            t3 = ((y - 4) & 255) // 8
            if not (t6 < 32 and (pf(t6, t5) or pf(t6, t3))):
                out.append((x - 1, y))
        # destra
        if x < 145:
            t5 = ((y - 1) & 255) // 8
            t6 = ((x - 9) & 255) // 4
            t3 = ((y - 4) & 255) // 8
            if not (t6 < 32 and (pf(t6, t5) or pf(t6, t3))):
                out.append((x + 1, y))
        return out

    def path(self, start, goals):
        prev = {start: None}
        q = deque([start])
        while q:
            p = q.popleft()
            if p in goals:
                out = []
                while p is not None:
                    out.append(p)
                    p = prev[p]
                return out[::-1]
            for n in self.moves(*p):
                if n not in prev:
                    prev[n] = p
                    q.append(n)
        return None


def sugar_goals(mx, my):
    hit = {(dx, dy) for dy in (1, 2, 3) for dx in range(-7, -1)} | {(dx, 0) for dx in (-6, -5, -4, -3)}
    return {(mx + dx, my + dy) for dx, dy in hit}


def ball_goals(bx, by):
    return {(x, y) for x in range(bx - 7, bx - 1) for y in range(by - 12, by + 4)}


# ---------------------------------------------------------------------
# azioni sul gioco
# ---------------------------------------------------------------------
def protect(s):
    """Congela le bocche (hitCooldown) e ricarica la barra del tempo."""
    s.poke({V["hitCooldown"]: 250, PFSCORE1: 0xFF})


WALK_SFX = set()   # effetti sonori visti durante l'ultima camminata


def walk_to(s, level, goals, max_time=40.0):
    """Muove il biscotto con i tasti lungo il percorso calcolato."""
    if moving(level):
        # gocce e presse sbarrano la strada a tratti e rallentano chi le tocca:
        # il test non sa aspettare il momento giusto, gli serve piu' tempo
        max_time *= 3
    WALK_SFX.clear()
    t0 = time.time()
    start_level_no = None
    last_protect = 0
    while time.time() - t0 < max_time:
        if time.time() - last_protect > 3.5:
            protect(s)
            last_protect = time.time()
        r = s.save()
        WALK_SFX.add(r.v("sfxId"))
        if start_level_no is None:
            start_level_no = r.v("level")
        if r.v("level") != start_level_no:
            return True, r  # il livello e' cambiato (sacchetto preso)
        pos = (r[PLAYER0X], r[PLAYER0Y])
        if pos in goals:
            return True, r
        g = Grid(r, level)
        path = g.path(pos, goals)
        if path is None:
            if moving(level):
                s.wait(0.15)       # una goccia o una pressa sbarra la strada: si aspetta
                continue
            return False, r
        # punta qualche passo avanti lungo il percorso
        k = min(len(path) - 1, 10)
        tx, ty = path[k]
        keys = []
        if tx > pos[0]:
            keys.append("Right")
        elif tx < pos[0]:
            keys.append("Left")
        if ty > pos[1]:
            keys.append("Down")
        elif ty < pos[1]:
            keys.append("Up")
        steps = max(abs(tx - pos[0]), abs(ty - pos[1]))
        slow = r.flag(6)
        dur = max(0.04, min(steps, 8) / 50.0) * (3.5 if slow else 1.0)
        s.hold(keys, dur)
    return False, s.save()


def start_level(s, level):
    """Dal titolo: Select (F1) per scegliere il livello, Reset (F2) per partire."""
    for _ in range(level - 1):
        s.tap("F1", 0.1)
        s.wait(0.15)
    s.tap("F2", 0.15)
    s.wait(0.8 + CARD)
    return s.save()


def static_checks(s, r, level):
    rows = r.pf_rows()
    print("\n".join("     " + x for x in rows))
    # 1) appoggi: ogni gruppo di pixel deve toccare soffitto (riga 0),
    #    piano di lavoro (riga 5) o pavimento (riga 10)
    drops = drop_cells(level)
    cells = {(c, rr) for rr in range(11) for c in range(32) if r.pf(c, rr) and (c, rr) not in drops}
    seen, floating = set(), []
    for c in sorted(cells):
        if c in seen:
            continue
        comp, q = set(), [c]
        while q:
            p = q.pop()
            if p in comp or p not in cells:
                continue
            comp.add(p)
            q += [(p[0] + 1, p[1]), (p[0] - 1, p[1]), (p[0], p[1] + 1), (p[0], p[1] - 1)]
        seen |= comp
        if not any(p[1] in (0, 5, 10) for p in comp):
            floating.append(sorted(comp))
    check(level, "nessun oggetto sospeso nel vuoto", not floating, str(floating[:3]))
    # 2) parte alta: ogni pixel in riga 4 ha il piano sotto
    unsupported = [c for c in range(32) if (c, 4) in cells and (c, 5) not in cells]
    check(level, "oggetti alti appoggiati sul piano", not unsupported, str(unsupported))
    # 3) parte bassa: ogni pixel in riga 6 (lampade, cioccolato appeso) ha il piano sopra
    hanging = [c for c in range(32) if (c, 6) in cells and (c, 5) not in cells]
    check(level, "lampade/oggetti bassi appesi al piano", not hanging, str(hanging))
    # 4) gocce: una sola goccia per colonna e appoggio presente
    bits = OBJECTS[level - 1][3]
    bad = []
    for i in range(8):
        if bits & (1 << i):
            col, top = 3 + 7 * (i % 4), (0 if i < 4 else 6)
            n = sum(r.pf(col, rr) for rr in range(top, top + 5))
            if n != 1 or (top == 6 and not r.pf(col, 5)):
                bad.append((col, top, n))
    if bits and level != model.PRESS_LEVEL:
        check(level, "gocce: un solo pixel che scende, appeso", not bad, str(bad))
    if bits and level == model.PRESS_LEVEL:
        # presse a T: perno continuo dall'alto (1-5 righe) e testa larga 3
        # colonne solo in fondo al perno
        bad = []
        for i in range(8):
            if bits & (1 << i):
                col, top = 3 + 7 * (i % 4), (0 if i < 4 else 6)
                on = [r.pf(col, rr) for rr in range(top, top + 5)]
                n = sum(on)
                head = top + n - 1
                sides = [rr for rr in range(top, top + 5) if r.pf(col - 1, rr) or r.pf(col + 1, rr)]
                ok = (1 <= n <= 5 and on == [1] * n + [0] * (5 - n) and (top == 0 or r.pf(col, 5))
                      and sides == [head] and r.pf(col - 1, head) and r.pf(col + 1, head))
                if not ok:
                    bad.append((col, top, on, sides))
        check(level, "presse a T: perno appeso al soffitto o al piano, testa larga in fondo", not bad, str(bad))


def footprint(x, y):
    cols = range(((x - 17) & 255) // 4, ((x - 10) & 255) // 4 + 1)
    rws = range(((y - 4) & 255) // 8, ((y - 1) & 255) // 8 + 1)
    return {(c, r) for c in cols for r in rws}


def shoot_spots(g, level, target, push):
    """Posizioni raggiungibili da cui il cioccolatino colpisce target, per
    direzione, senza essere appoggiati all'oggetto (toccandolo scatta lo
    slow motion e in slow motion il BAS non fa sparare)."""
    steps = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}
    return steps


def shoot_pixel(s, level, target):
    """Va in una posizione da cui il cioccolatino colpisce target e spara."""
    r = s.save()
    g = Grid(r, level)
    push = walls(r) or None
    start = (r[PLAYER0X], r[PLAYER0Y])
    steps = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}
    keys = {"up": "Up", "down": "Down", "left": "Left", "right": "Right"}
    spots = {d: set() for d in steps}
    first = None
    seen, q = {start}, deque([start])
    while q:
        p = q.popleft()
        for d, st in steps.items():
            if missile_hit(g, p[0], p[1], d, level, push) != target:
                continue
            q2, free = p, True
            for _ in range(3):
                nxt = (q2[0] + st[0], q2[1] + st[1])
                if nxt not in g.moves(*q2):
                    free = False
                    break
                q2 = nxt
            if free:
                spots[d].add(p)
                if first is None:
                    first = d
        for n in g.moves(*p):
            if n not in seen:
                seen.add(n)
                q.append(n)
    if first is None:
        print(f"     (nessuna posizione da cui colpire {target})")
        return False
    d = first
    for _ in range(3):
        ok, r = walk_to(s, level, spots[d])
        if not ok:
            print(f"     (non raggiungo una posizione di tiro verso {d})")
        r = s.save()
        s.poke({V["flags"]: r.v("flags") & ~0xC0, V["hitCooldown"]: 250})
        # direzione e fuoco nello stesso istante
        s.down(keys[d], "space")
        s.wait(0.06)
        s.up(keys[d], "space")
        heard = sfx_seen(s, 0.5)
        r = s.save()
        if not r.pf(*target):
            check(level, f"suono del blocco abbattuto {target}", SFX["blocco"] in heard,
                  f"effetti sentiti={sorted(heard)}")
            return True
    return False


def cheapest_path(fg, start, goals, breakable):
    """Percorso che richiede di bucare il minor numero di blocchi."""
    import heapq
    dist = {start: 0}
    prev = {start: None}
    heap = [(0, start)]
    while heap:
        d, p = heapq.heappop(heap)
        if d > dist[p]:
            continue
        if p in goals:
            out = []
            while p is not None:
                out.append(p)
                p = prev[p]
            return out[::-1]
        for n in fg.moves(*p):
            nd = d + 1 + 60 * len(footprint(*n) & breakable)
            if nd < dist.get(n, 1 << 30):
                dist[n] = nd
                prev[n] = p
                heapq.heappush(heap, (nd, n))
    return None


def open_way(s, level, goals, max_shots=30):
    """Buca gli oggetti distruttibili che separano il biscotto dallo zuccherino."""
    if level == model.PRESS_LEVEL:
        return True, 0     # solo presse: niente da bucare, la strada si apre aspettando
    shots = 0
    while shots < max_shots:
        r = s.save()
        g = Grid(r, level)
        start = (r[PLAYER0X], r[PLAYER0Y])
        if g.path(start, goals) is not None:
            return True, shots
        push = walls(r) or None
        final, destroyed, _ = destroy_closure(g.cells, level, start=start, push_col=push)
        destroyed -= drop_cells(level)
        fpath = cheapest_path(model.Grid(final), start, goals, g.cells & destroyed)
        if fpath is None:
            print(f"     (nessun percorso nemmeno bucando, da {start})")
            return False, shots
        target = None
        for p in fpath:
            blocking = sorted(c for c in footprint(*p) if c in g.cells and c in destroyed)
            if blocking:
                target = blocking[0]
                break
        if target is None:
            print(f"     (nessun blocco da bucare trovato sul percorso)")
            return False, shots
        if not shoot_pixel(s, level, target):
            r = s.save()
            print(f"     (non riesco a bucare {target}: biscotto in ({r[PLAYER0X]},{r[PLAYER0Y]}))")
            return False, shots
        shots += 1
    return False, shots


WALL_NAMES = ("wall0", "wall1", "wall2", "wall3", "wall4")


def move_wall(s, k, target, max_time=25.0):
    """Riporta il muro k nella colonna target spingendolo (il biscotto viene
    messo dal lato giusto del muro, sul pavimento o sul piano)."""
    t0 = time.time()
    y = model.wall_y(target)
    while time.time() - t0 < max_time:
        r = s.save()
        key = r.v(WALL_NAMES[k])
        if key == target:
            return True
        c = key & 127
        if c < target & 127:
            s.poke({PLAYER0X: 4 * c + 9 - 3, PLAYER0Y: y, V["hitCooldown"]: 250})
            s.hold(["Right"], 0.14)   # al massimo una colonna (un passo ogni 8 frame)
        else:
            s.poke({PLAYER0X: 4 * c + 18 + 2, PLAYER0Y: y, V["hitCooldown"]: 250})
            s.hold(["Left"], 0.14)
    return False


def push_open(s, level, goals, attempts=4):
    """Se l'obiettivo non si raggiunge, cerca le spinte dei muri (anche piu'
    d'una di fila, come farebbe il giocatore) che aprono la strada e le
    esegue con i tasti. Dopo ogni giro ricontrolla e, se serve, ripianifica."""
    how = None
    for _ in range(attempts):
        r = s.save()
        g = Grid(r, level)
        start = (r[PLAYER0X], r[PLAYER0Y])
        if g.path(start, goals) is not None:
            return how is not None, how
        idx = [i for i, n in enumerate(WALL_NAMES) if r.v(n) != 255]
        ws = tuple(r.v(WALL_NAMES[i]) for i in idx)
        static = g.cells - model.wall_cells(ws)
        protect(s)                     # (Stella corre mentre si calcola il piano)
        plan = model.plan_pushes(static, ws, start, goals, max_states=600)
        protect(s)
        if not plan:
            return False, how
        for wi, d, n, new, _at in plan:
            r = s.save()
            cur = tuple(r.v(WALL_NAMES[i]) for i in idx)
            reach = model.Grid(static | model.wall_cells(cur)).reachable((r[PLAYER0X], r[PLAYER0Y]))
            how = (idx[wi] + 1, "destra" if d == 1 else "sinistra", n)
            walk_to(s, level, model.can_push(reach, cur[wi], d))
            name, target = WALL_NAMES[idx[wi]], new[wi]
            key = "Right" if d == 1 else "Left"
            t0 = time.time()
            while time.time() - t0 < 8:
                r = s.save()
                if ((r.v(name) & 127) - (target & 127)) * d >= 0:
                    break
                s.hold([key], 0.05)
    r = s.save()
    return Grid(r, level).path((r[PLAYER0X], r[PLAYER0Y]), goals) is not None and how is not None, how


def sugar_phase(s, level):
    s.poke({V["hitCooldown"]: 250})
    r0 = s.save()
    secs = sorted(((sugar_cell(v)[0] - 1) // 8 + (4 if sugar_cell(v)[1] > 5 else 0))
                  for v in SUGAR[(level - 1) * 8:level * 8])
    check(level, "zuccherini distribuiti: uno per ogni sezione b0..b7", secs == list(range(8)), str(secs))
    for k in range(8):
        r = s.save()
        v = SUGAR[(level - 1) * 8 + k]
        ex, ey = sugar_xy(v)
        # uno alla volta: posizione ferma su tre letture
        pos = []
        for _ in range(3):
            rr = s.save()
            bits = rr.v("choco_bits")
            idx = next((i for i in range(8) if not bits >> i & 1), 8)
            pos.append((rr[SUGARX], rr[SUGARY], idx))
            s.wait(0.07)
        steady = all(p == (ex, ey, k) for p in pos)
        check(level, f"zuccherino {k}: visibile da solo e fermo in ({ex},{ey})", steady, str(pos))
        col, row = sugar_cell(v)
        inside = r0.pf(col, row)
        lamps = model.lamp_cells(level)
        ok_place = (not inside) or (row in DESTRUCTIBLE_ROWS and (col, row) not in lamps)
        check(level, f"zuccherino {k}: " + ("dentro un oggetto distruttibile" if inside else "fuori dagli oggetti"),
              ok_place, f"cella pf ({col},{row})")
        goals = sugar_goals(ex, ey)
        if level in PUSH_SUGARS and v in PUSH_SUGARS[level]:
            rr = s.save()
            blocked = Grid(rr, level).path((rr[PLAYER0X], rr[PLAYER0Y]), goals) is None
            if walls(rr) != model.wall_cols(level) and not blocked:
                # la strada l'ha gia' aperta una spinta per uno zuccherino precedente
                check(level, f"zuccherino {k}: gia' aperto spingendo un muro prima", True, str(walls(rr)))
            else:
                check(level, f"zuccherino {k}: senza spingere un muro non si raggiunge", blocked)
                okp, how = push_open(s, level, goals)
                check(level, f"zuccherino {k}: raggiunto spingendo un muro", okp and how is not None,
                      f"muro {how[0]} a {how[1]} di {how[2]} colonne" if how else "nessuna spinta utile")
        opened, shots = open_way(s, level, goals)
        check(level, f"zuccherino {k}: raggiungibile" + (f" (bucati {shots} blocchi)" if shots else ""), opened)
        if not opened:
            s.poke({V["choco_bits"]: r.v("choco_bits") | (1 << k), V["choco_count"]: k + 1})
            continue
        ok, r = walk_to(s, level, goals)
        heard = sfx_seen(s, 0.3, r) | (WALK_SFX - {0})
        r = s.save()
        got = (r.v("choco_bits") >> k) & 1
        want = SFX["potere"] if k == 0 else SFX["zuccherino"]
        if got:
            check(level, f"zuccherino {k}: suono " + ("del super potere" if k == 0 else "dello zuccherino"),
                  want in heard, f"effetti sentiti={sorted(heard)}")
        check(level, f"zuccherino {k}: raccolto camminando", ok and got and r.v("choco_count") == k + 1,
              f"bits={bin(r.v('choco_bits'))} count={r.v('choco_count')}")
        if not got:
            s.poke({V["choco_bits"]: r.v("choco_bits") | (1 << k), V["choco_count"]: k + 1})
        if k == 0:
            check(level, "zuccherino dorato: congela le bocche (_hitCooldown)", r.v("hitCooldown") > 0)
        if k == 1:
            check(level, "zuccherino 1: chiave (_b2_hasKey)", r.flag(2) == 1)
    r = s.save()
    check(level, "8 zuccherini, nessuno contato due volte", r.v("choco_count") == 8 and r.v("choco_bits") == 0xFF,
          f"count={r.v('choco_count')}")
    check(level, "dopo l'ultimo non compare piu' nulla", r[SUGARY] == 200)
    if r.flag(5) == 1:
        check(level, "il sacchetto non appare prima di colpire la bocca", r[BALLY] != 28)
    else:
        # un cioccolatino sparato agli oggetti ha gia' colpito una bocca:
        # in quel caso il sacchetto deve essere comparso
        check(level, "bocca gia' colpita da un colpo precedente: il sacchetto e' comparso",
              r[BALLY] == 28, f"score={r.score()}")


def mouth_phase(s, level):
    # cerca una posizione raggiungibile con 30 px liberi a destra sulla stessa
    # riga (22 nel livello delle presse, dove tra due presse c'e' meno
    # spazio: si riprova finche' le presse non lasciano libera una linea)
    span = 22 if level == model.PRESS_LEVEL else 30
    best = None
    for _ in range(20 if level == model.PRESS_LEVEL else 1):
        r = s.save()
        g = Grid(r, level)
        start = (r[PLAYER0X], r[PLAYER0Y])
        prev = {start: None}
        q = deque([start])
        while q:
            x, y = q.popleft()
            row = ((y - 3) & 255) // 8
            if x < 100 and all(not g.pf(c, row) and not g.pf(c, ((y - 4) & 255) // 8)
                               for c in range(((x - 9) & 255) // 4, ((x + span) - 9) // 4 + 1)):
                best = (x, y)
                break
            for n in g.moves(x, y):
                if n not in prev:
                    prev[n] = (x, y)
                    q.append(n)
        if best:
            break
        s.wait(0.1)
    if not check(level, "trovata una linea di tiro libera", best is not None):
        return
    ok, r = walk_to(s, level, {(best[0] + dx, best[1] + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)})
    check(level, f"raggiunta la posizione di tiro {best}", ok, f"p0=({r[PLAYER0X]},{r[PLAYER0Y]})")
    # suono dello sparo: un colpo a vuoto, con le bocche lontane (se il
    # colpo prende subito la bocca, il suono della bocca uccisa, piu'
    # importante, copre lo sparo prima che lo si possa leggere)
    r = s.save()
    x, y = r[PLAYER0X], r[PLAYER0Y]
    far = y - 30 if y > 40 else y + 30
    shot_heard = set()
    for _ in range(3):      # (nel livello delle presse una pressa puo' rallentare il biscotto)
        r = s.save()
        s.poke({V["flags"]: r.v("flags") & ~0xC0, V["mouth0x"]: x + 26, V["mouth0y"]: far,
                V["mouth1x"]: x + 26, V["mouth1y"]: far, V["hitCooldown"]: 200, PLAYER0X: x, PLAYER0Y: y})
        s.down("Right")
        s.down("space")
        shot_heard |= sfx_seen(s, 0.12)
        s.up("space")
        s.up("Right")
        s.wait(1.2)
        if SFX["sparo"] in shot_heard:
            break
    # il biscotto torna nella posizione di tiro
    r = s.save()
    s.poke({PLAYER0X: x, PLAYER0Y: y, V["flags"]: r.v("flags") & ~0xC0, V["hitCooldown"]: 200})
    attempts = 0
    for attempts in range(1, 4):
        s.hold(["Right"], 0.06)
        r = s.save()
        x, y = r[PLAYER0X], r[PLAYER0Y]
        score0 = r.score()
        # la bocca (ferma per _hitCooldown) viene messa davanti al biscotto, niente slow motion
        mx = x + (18 if level == model.PRESS_LEVEL else 26)   # tra le presse c'e' poco spazio
        # (la seconda bocca va su un'altra riga: tenendo premuto il fuoco
        # parte subito un altro cioccolatino, che la colpirebbe)
        my1 = y + 30 if y < 50 else y - 30
        s.poke({V["flags"]: r.v("flags") & ~0xC0, V["mouth0x"]: mx, V["mouth0y"]: y,
                V["mouth1x"]: mx, V["mouth1y"]: my1, V["hitCooldown"]: 200})
        # destra e fuoco premuti insieme, come un giocatore vero
        s.down("Right")
        s.down("space")
        # si ascolta gia' mentre i tasti sono premuti: se il biscotto tocca un
        # oggetto la scossa (priorita' piu' alta) copre subito lo sparo
        heard = sfx_seen(s, 0.12)
        s.up("space")
        s.up("Right")
        heard |= sfx_seen(s, 0.7)
        r = s.save()
        if r.flag(5) == 0:
            break
    check(level, "suoni: sparo e bocca uccisa", SFX["bocca"] in heard and SFX["sparo"] in shot_heard | heard,
          f"effetti sentiti={sorted(shot_heard)} poi {sorted(heard)}")
    check(level, "cioccolatino colpisce la bocca: +10 (una volta sola) e bocca colpita",
          r.flag(5) == 0 and r.score() == score0 + 10,
          f"flag5={r.flag(5)} score {score0}->{r.score()} tentativi={attempts}")
    dead = [i for i in (0, 1) if r.v(f"mouth{i}wait") > 0]
    check(level, "la bocca colpita sparisce (attesa prima di ricomparire)",
          len(dead) == 1 and r.v(f"mouth{dead[0]}y") == 200,
          f"attese={r.v('mouth0wait')},{r.v('mouth1wait')}")
    if dead:
        i = dead[0]
        t0 = time.time()
        while time.time() - t0 < 9 and r.v(f"mouth{i}wait") > 0:
            s.wait(0.25)
            r = s.save()
        elapsed = time.time() - t0
        corner = (20, 8) if i == 0 else (140, 90)
        check(level, "dopo circa 4 secondi la bocca ricompare nel suo angolo",
              r.v(f"mouth{i}wait") == 0 and 2.5 <= elapsed <= 7 and
              # (tra due letture passano fino a ~0,45 s: la bocca puo' gia' aver fatto qualche passo, al livello 6 anche 7 px)
              abs(r.v(f"mouth{i}x") - corner[0]) <= 12 and abs(r.v(f"mouth{i}y") - corner[1]) <= 12,
              f"dopo {elapsed:.1f} s in ({r.v(f'mouth{i}x')},{r.v(f'mouth{i}y')})")
    s.wait(0.3)
    r = s.save()
    exp_bx = OBJECTS[level - 1][7]
    check(level, f"sacchetto apparso in ({exp_bx},28)", r[BALLY] == 28 and r[BALLX] == exp_bx,
          f"ball=({r[BALLX]},{r[BALLY]})")


def bag_phase(s, level):
    r = s.save()
    nxt = level + 1     # dopo l'ultimo livello c'e' la Bocca Gigante (BOSS)
    if r.v("level") == nxt:
        # il biscotto e' gia' passato sul sacchetto nella fase precedente
        check(level, "sacchetto raggiungibile", True, "preso durante la fase precedente")
        check(level, "toccando il sacchetto si passa al livello successivo", True, f"level={r.v('level')}")
        return r
    goals = ball_goals(r[BALLX], r[BALLY])
    g = Grid(r, level)
    if level == model.PRESS_LEVEL:
        g.cells -= drop_cells(level)    # le presse si attraversano aspettando
    # dal punto di partenza del livello e dalla posizione attuale
    p = g.path((10, 64), goals) or g.path((r[PLAYER0X], r[PLAYER0Y]), goals)
    check(level, "sacchetto raggiungibile", p is not None, f"p0=({r[PLAYER0X]},{r[PLAYER0Y]})")
    if p is None:
        print("\n".join("     " + x for x in r.pf_rows()))
    ok, r = walk_to(s, level, goals)
    if p is None:
        print(f"     (camminata verso il sacchetto: ok={ok} level={r.v('level')} p0=({r[PLAYER0X]},{r[PLAYER0Y]}))")
    deadline = time.time() + 30
    while time.time() < deadline and r.v("level") == level:
        # avvicinamento fine finche' non tocca il sacchetto; se il biscotto
        # e' uscito dalla zona del sacchetto si ricalcola il percorso.
        # Toccato il sacchetto, il bonus tempo dura fino a circa 1 secondo.
        if (r[PLAYER0X], r[PLAYER0Y]) not in goals and r[BALLY] == 28:
            # se il bonus tempo sta contando (barra che cala) il sacchetto
            # e' gia' stato toccato: non si cammina piu'
            s.wait(0.3)
            r2 = s.save()
            if r2.v("level") != level or r2[PFSCORE1] != r[PFSCORE1]:
                r = r2
                continue
            ok, r = walk_to(s, level, goals, 10.0)
            continue
        s.hold(["Up"], 0.04)
        r = s.save()
    check(level, "toccando il sacchetto si passa al livello successivo", r.v("level") == nxt,
          f"level={r.v('level')}")
    heard = sfx_seen(s, 0.2, r)
    check(level, "suono del cambio livello", SFX["livello"] in heard, f"effetti sentiti={sorted(heard)}")
    if CARD:
        s.wait(CARD + (OVER if level == BOSS else 0))
        r = s.save()
    # il numero del livello cambia subito, ma il livello nuovo si carica
    # dopo il conteggio del bonus tempo: si aspetta il biscotto alla partenza
    t0 = time.time()
    while time.time() - t0 < 5 and (r[PLAYER0X], r[PLAYER0Y]) != (10, 64):
        s.wait(0.1)
        r = s.save()
    if True:
        check(nxt, "partenza dal punto (10,64) con 4 vite e tempo pieno",
              abs(r[PLAYER0X] - 10) <= 16 and abs(r[PLAYER0Y] - 64) <= 16 and r[PFSCORE2] == 0xAA and r[PFSCORE1] == 0xFF,
              f"p0=({r[PLAYER0X]},{r[PLAYER0Y]}) vite={r[PFSCORE2]:08b} tempo={r[PFSCORE1]:08b}")
    return r


def push_phase(s, level):
    r = s.save()
    keys = walls(r)
    exp = model.wall_cols(level)
    check(level, f"muri spingibili disegnati: {exp} (colonna, +128 = sul piano, righe 2-4; "
          "altrimenti sul pavimento, righe 8-10)",
          keys == exp and all(r.pf(c, rr) for c, rr in model.wall_cells(keys)), f"muri={keys}")
    check(level, "muri sia sopra sia sotto il piano",
          any(k & 128 for k in exp) and any(not k & 128 for k in exp))
    s.shot(f"{OUT}/atari_L{level}_muri.png")
    names = WALL_NAMES
    for k, key in enumerate(keys):
        c, rows_k, y = key & 127, model.wall_rows(key), model.wall_y(key)
        where = "sul piano" if key & 128 else "sul pavimento"
        # biscotto a sinistra del muro, Destra tenuto premuto
        s.poke({PLAYER0X: 4 * c + 9 - 3, PLAYER0Y: y, V["hitCooldown"]: 250})
        s.down("Right")
        heard = sfx_seen(s, 1.4)
        s.up("Right")
        r = s.save()
        key2 = r.v(names[k])
        c2 = key2 & 127
        check(level, f"muro {k + 1} ({where}): suono del muro spinto", SFX["muro"] in heard,
              f"effetti sentiti={sorted(heard)}")
        ok_cols = (key2 & 128 == key & 128 and all(r.pf(c2, rr) for rr in rows_k)
                   and not any(r.pf(c, rr) for rr in rows_k))
        check(level, f"muro {k + 1} ({where}): spingendo a destra si sposta", c2 > c and ok_cols,
              f"colonna {c}->{c2}")
        check(level, f"muro {k + 1}: spingere non attiva lo slow motion", r.flag(6) == 0)
        s.poke({PLAYER0X: 4 * c2 + 18 + 2, PLAYER0Y: y, V["hitCooldown"]: 250})
        s.hold(["Left"], 1.4)
        r = s.save()
        c3 = r.v(names[k]) & 127
        check(level, f"muro {k + 1} ({where}): spingendo a sinistra torna indietro", c3 < c2,
              f"colonna {c2}->{c3}")
    # il cioccolatino non distrugge i muri (uno sul piano e uno sul pavimento)
    for key in ([k for k in walls(r) if k & 128][:1] + [k for k in walls(r) if not k & 128][:1]):
        c = key & 127
        r = s.save()
        s.poke({PLAYER0X: 4 * c + 18 + 14, PLAYER0Y: model.wall_y(key), V["hitCooldown"]: 250,
                V["flags"]: r.v("flags") & ~0xC0})
        s.down("Left", "space")
        s.wait(0.08)
        s.up("Left", "space")
        s.wait(0.8)
        r = s.save()
        check(level, f"il cioccolatino non distrugge il muro {'sul piano' if key & 128 else 'sul pavimento'}",
              all(r.pf(c, rr) for rr in model.wall_rows(key)))
    # --- il muro schiaccia la bocca ---
    r = s.save()
    c = [k for k in walls(r) if not k & 128][0]
    score0 = r.score()
    # bocca 0 subito a sinistra del muro, sul pavimento (ferma per _hitCooldown);
    # il biscotto spinge il muro verso sinistra, sopra la bocca
    s.poke({V["mouth0x"]: 4 * (c - 1) + 17 - 8, V["mouth0y"]: 84, V["mouth1x"]: 140, V["mouth1y"]: 20,
            V["mouth0wait"]: 0, V["mouth1wait"]: 0, V["flags"]: (r.v("flags") | 0x20) & ~0x40,
            PLAYER0X: 4 * c + 18 + 2, PLAYER0Y: 84, V["hitCooldown"]: 250})
    s.hold(["Left"], 0.6)
    r = s.save()
    check(level, "spingendo il muro sulla bocca la si uccide (+10, conta come bocca colpita)",
          r.v("mouth0wait") > 0 and r.v("mouth0y") == 200 and r.score() == score0 + 10 and r.flag(5) == 0,
          f"attesa={r.v('mouth0wait')} y={r.v('mouth0y')} score {score0}->{r.score()} flag5={r.flag(5)}")
    s.shot(f"{OUT}/atari_L{level}_bocca_schiacciata.png")
    # i muri tornano nelle colonne di partenza (lo schema degli zuccherini
    # e' pensato con i muri al loro posto)
    back = all(move_wall(s, k, c) for k, c in enumerate(exp))
    check(level, "i muri tornano nelle colonne di partenza", back, str(walls(s.save())))
    # si riparte puliti: bocche negli angoli, bocca non ancora colpita
    r = s.save()
    s.poke({V["mouth0wait"]: 0, V["mouth1wait"]: 0, V["mouth0x"]: 20, V["mouth0y"]: 8,
            V["mouth1x"]: 140, V["mouth1y"]: 90, V["flags"]: r.v("flags") | 0x20,
            PLAYER0X: 10, PLAYER0Y: 64, V["hitCooldown"]: 250})


def light_phase(s, level):
    s.poke({V["seconds"]: 31, V["frame"]: FRAME_LIMIT, V["hitCooldown"]: 250})
    s.wait(0.4)
    r = s.save()
    check(level, "dopo 32 secondi la luce si spegne", r.flag(4) == 0)
    s.shot(f"{OUT}/atari_L{level}_buio.png")
    # sotto un pezzo di piano di lavoro, spara in alto
    g = Grid(r, level)
    start = (r[PLAYER0X], r[PLAYER0Y])
    target = None
    for c in range(2, 30):
        if r.pf(c, 5) and r.pf(c + 1, 5):
            x = 4 * c + 18 - 4
            for y in range(54, 62):
                if g.path(start, {(x, y)}) is not None and not g.pf(((x + 4 - 18) & 255) // 4, 5 + 1):
                    target = (x, y)
                    break
        if target:
            break
    if not check(level, "trovato un punto sotto il piano", target is not None):
        return
    # (ci si mette direttamente: camminando si potrebbe toccare il sacchetto,
    # gia' apparso, e passare al livello dopo)
    s.poke({PLAYER0X: target[0], PLAYER0Y: target[1], V["hitCooldown"]: 250})
    s.wait(0.2)
    before = [s.save().pf(c, 5) for c in range(32)]
    for attempts in range(1, 4):
        r = s.save()
        s.poke({V["flags"]: r.v("flags") & ~0xC0})
        # su e fuoco insieme: il cioccolatino parte verso l'alto anche se
        # il biscotto e' gia' appoggiato sotto il piano
        s.down("Up")
        s.tap("space", 0.12)
        s.up("Up")
        s.wait(0.6)
        r = s.save()
        if r.flag(4) == 1:
            break
        print(f"     (tentativo {attempts}: p0=({r[PLAYER0X]},{r[PLAYER0Y]}) dir={r.v('dir'):08b})")
    check(level, "sparando sul piano la luce si riaccende", r.flag(4) == 1)
    # trucco: il primo colpo toglie un pezzo di piano (4 colonne), uno solo
    # per livello
    after = [r.pf(c, 5) for c in range(32)]
    gone = [c for c in range(32) if before[c] and not after[c]]
    check(level, "il colpo toglie un pezzo di piano (al massimo 4 colonne vicine)",
          gone and max(gone) - min(gone) <= 3, f"colonne tolte={gone}")
    spot = None
    for c in range(2, 30):
        # (biscotto nelle colonne c-1..c+1: niente oggetti sotto il piano, se
        # no lo rallentano e da rallentato non spara)
        if after[c] and after[c + 1] and all(abs(c - g) > 5 for g in gone) and \
                not any(r.pf(k, 6) or r.pf(k, 7) for k in range(c - 1, c + 3)):
            spot = c
            break
    if spot is not None:
        # (il biscotto, con Su premuto, puo' essere salito nel buco: lo si
        # rimette sotto il piano, sotto un altro pezzo)
        s.poke({PLAYER0X: 4 * spot + 14, PLAYER0Y: target[1], V["flags"]: r.v("flags") & ~0xD0,
                V["hitCooldown"]: 250})
        s.wait(0.2)
        s.down("Up")
        s.tap("space", 0.12)
        s.up("Up")
        s.wait(0.6)
        r = s.save()
        again = [c for c in range(32) if after[c] and not r.pf(c, 5)]
        check(level, "un secondo colpo riaccende la luce ma non toglie altri pezzi",
              r.flag(4) == 1 and not again, f"luce={r.flag(4)} altre colonne tolte={again}")


def slow_sound_phase(s, level):
    """Toccando un oggetto parte il rallentamento con il suono della scossa."""
    r = s.save()
    g = Grid(r, level)
    reach = model.Grid(g.cells).reachable()
    spot = None
    fixed = {(c, rr) for rr in range(11) for c in range(32) if r.pf(c, rr)} - drop_cells(level)
    fixed -= model.wall_cells(walls(r))
    for (x, y) in sorted(reach):
        if x >= 140 or not 20 < y < 88 or (x + 1, y) in g.moves(x, y):
            continue
        # a destra c'e' un oggetto fisso vero (non una goccia, non un muro mobile)
        col = ((x - 9) & 255) // 4
        if (col, ((y - 1) & 255) // 8) in fixed or (col, ((y - 4) & 255) // 8) in fixed:
            spot = (x, y)
            break
    if not check(level, "trovato un oggetto da toccare", spot is not None):
        return
    s.poke({PLAYER0X: spot[0], PLAYER0Y: spot[1], V["flags"]: r.v("flags") & ~0x48, V["hitCooldown"]: 250,
            V["seconds"]: 1})
    s.down("Right")
    heard = sfx_seen(s, 0.4)
    s.up("Right")
    r = s.save()
    check(level, "toccando un oggetto: rallentamento e suono della scossa",
          r.flag(6) == 1 and SFX["scossa"] in heard, f"slow={r.flag(6)} effetti sentiti={sorted(heard)}")
    s.poke({V["flags"]: r.v("flags") & ~0x48, PLAYER0X: 10, PLAYER0Y: 64})


def life_phase(s, level):
    r = s.save()
    lives = r[PFSCORE2]
    s.poke({PFSCORE1: 0x80, V["seconds"]: 15, V["frame"]: FRAME_LIMIT, V["hitCooldown"]: 0,
            V["mouth0x"]: 20, V["mouth0y"]: 8, V["mouth1x"]: 140, V["mouth1y"]: 90})
    s.wait(0.5)
    r = s.save()
    check(level, "barra del tempo finita: si perde una vita e il tempo riparte", r[PFSCORE2] == lives >> 2 and
          r[PFSCORE1] == 0xFF and r.v("hitCooldown") > 0, f"vite {lives:08b}->{r[PFSCORE2]:08b}")
    lives = r[PFSCORE2]
    x, y = r[PLAYER0X], r[PLAYER0Y]
    s.poke({V["hitCooldown"]: 0, V["mouth0x"]: x, V["mouth0y"]: y, V["mouth1x"]: x, V["mouth1y"]: y})
    s.wait(0.3)
    r = s.save()
    check(level, "toccando la bocca si perde una vita", r[PFSCORE2] == lives >> 2, f"{lives:08b}->{r[PFSCORE2]:08b}")
    s.poke({PFSCORE2: 0xAA, V["mouth0x"]: 20, V["mouth0y"]: 8, V["mouth1x"]: 140, V["mouth1y"]: 90,
            V["hitCooldown"]: 250})


def mouth_pass_phase(s, level):
    """La bocca deve passare sopra a qualsiasi oggetto (tutti i livelli)."""
    r = s.save()
    # un pixel del playfield fuori dal piano, con spazio a sinistra e a destra
    target = None
    for row in (8, 9, 2, 3, 6, 7, 0, 1, 4, 10):
        for c in range(4, 24):
            if r.pf(c, row) and not r.pf(c - 3, row) and not r.pf(c + 6, row):
                target = (c, row)
                break
        if target:
            break
    if not check(level, "trovato un oggetto da far attraversare alla bocca", target is not None):
        return
    c, row = target
    if level == model.PRESS_LEVEL:
        # la colonna del perno (3 + 7k), anche se il pixel trovato e' il
        # bordo della testa larga
        c = 3 + 7 * round((c - 3) / 7)
    y = row * 8 + 7
    mx = 4 * c + 17 - 14          # bocca a sinistra dell'oggetto
    px = mx + 44                   # biscotto a destra, stessa riga
    if level == model.PRESS_LEVEL:
        # biscotto 9 colonne dopo la pressa (colonne c+9..c+10): fuori dalle
        # presse (le teste coprono c-1..c+1 ogni 7 colonne) e abbastanza
        # lontano perche' la bocca (larga 16) superi la pressa prima di toccarlo
        px = mx + 50
    lives = r[PFSCORE2]
    s.poke({V["mouth0x"]: mx, V["mouth0y"]: y, V["mouth1x"]: mx, V["mouth1y"]: y,
            PLAYER0X: px, PLAYER0Y: y, V["hitCooldown"]: 0})
    # attesa sufficiente alla velocita' del livello (frame per passo)
    s.wait(min(8.0, 1.0 + 30 * r.v("speed") / 50.0))
    r = s.save()
    m = max(r.v("mouth0x"), r.v("mouth1x"))
    check(level, f"la bocca passa sopra all'oggetto in ({c},{row})", m >= 4 * c + 17 + 2,
          f"bocca da x={mx} a x={m}, oggetto a x={4 * c + 17}")
    if level > 3:
        both = r.v("mouth0x") > mx + 4 and r.v("mouth1x") > mx + 4
        check(level, "si muovono tutte e due le bocche", both,
              f"bocca0 x={r.v('mouth0x')} bocca1 x={r.v('mouth1x')} (partenza {mx})")
    s.shot(f"{OUT}/atari_L{level}_bocca_passa.png")
    s.poke({PFSCORE2: lives, V["mouth0x"]: 20, V["mouth0y"]: 8, V["mouth1x"]: 140, V["mouth1y"]: 90,
            PLAYER0X: 10, PLAYER0Y: 64, V["hitCooldown"]: 250})


def drop_phase(s, level):
    """Ogni goccia scende fino al piano (sopra) o al pavimento (sotto)."""
    bits = OBJECTS[level - 1][3]
    low = {}
    t0 = time.time()
    while time.time() - t0 < 4.5:
        r = s.save()
        for i in range(8):
            if bits & (1 << i):
                col, top = 3 + 7 * (i % 4), (0 if i < 4 else 6)
                rows = [rr for rr in range(top, top + 5) if r.pf(col, rr)]
                if rows:
                    low[i] = max(low.get(i, 0), rows[-1])
        s.wait(0.1)
    exp = {i: (4 if i < 4 else 10) for i in range(8) if bits & (1 << i)}
    check(level, "le gocce arrivano fino al piano (riga 4) e al pavimento (riga 10)", low == exp,
          f"riga piu' bassa raggiunta={low}")


def press_phase(s, level):
    """Le presse si allungano fino in fondo e schiacciano il biscotto (una
    vita); stando fermi accanto a un oggetto non si perde niente."""
    r = s.save()
    seen = set()
    for _ in range(24):
        r = s.save()
        seen.add(sum(r.pf(10, rr) for rr in range(5)))
        s.wait(0.08)
    check(level, "la pressa (colonna 10) si allunga e si ritira: da 1 a 5 righe",
          1 in seen and 5 in seen, f"lunghezze viste={sorted(seen)}")
    # biscotto sotto la pressa, nella riga 4 (l'ultima che la pressa raggiunge)
    r = s.save()
    s.poke({PLAYER0X: 54, PLAYER0Y: 36, V["hitCooldown"]: 0, V["mouth0wait"]: 250, V["mouth1wait"]: 250,
            PFSCORE2: 0xAA, V["flags"]: r.v("flags") & ~0x40})
    # (la pressa fa un ciclo ogni 2 secondi: si aspetta il primo colpo)
    t0 = time.time()
    while time.time() - t0 < 3.0:
        s.wait(0.1)
        r = s.save()
        if r[PFSCORE2] != 0xAA:
            break
    check(level, "la pressa che scende sul biscotto lo schiaccia: una vita in meno",
          r[PFSCORE2] == 0x2A and r.v("hitCooldown") > 0, f"vite={r[PFSCORE2]:08b}")
    # fermo a contatto col piano, sotto e sopra, lontano dalle presse
    # (colonne 5-7): nessuna vita persa (toccare il playfield fermo non e'
    # essere schiacciati)
    for py, where in ((53, "sotto"), (39, "sopra")):
        s.save()
        s.poke({PLAYER0X: 40, PLAYER0Y: py, V["hitCooldown"]: 0, V["mouth0wait"]: 250, V["mouth1wait"]: 250,
                PFSCORE2: 0xAA})
        s.wait(1.5)
        r = s.save()
        check(level, f"fermo a contatto col piano ({where}): nessuna vita persa", r[PFSCORE2] == 0xAA,
              f"vite={r[PFSCORE2]:08b} pos=({r[PLAYER0X]},{r[PLAYER0Y]})")
    s.poke({V["mouth0wait"]: 0, V["mouth1wait"]: 0, PLAYER0X: 10, PLAYER0Y: 64, V["hitCooldown"]: 250,
            PFSCORE2: 0xAA, PFSCORE1: 0xFF})


def play_level(s, level, extra=True):
    r = s.save()
    check(level, "livello caricato", r.v("level") == level and r.flag(0) == 1, f"level={r.v('level')}")
    exp_speed = MOUTH_SPEED[level - 1] - 2 * r.v("lap")
    if exp_speed < 2 or 2 * r.v("lap") >= MOUTH_SPEED[level - 1] - 2:
        exp_speed = 2
    check(level, "velocita' delle bocche (frame per passo)", r.v("speed") == exp_speed,
          f"speed={r.v('speed')} atteso={exp_speed} giro={r.v('lap')}")
    if level == 1:
        check(level, "partenza dal punto (10,64) con 4 vite e tempo pieno",
              (r[PLAYER0X], r[PLAYER0Y]) == (10, 64) and r[PFSCORE2] == 0xAA and r[PFSCORE1] == 0xFF)
    check(level, f"luce: spenta solo al livello {LEVELS}", r.flag(4) == (0 if level == LEVELS else 1))
    static_checks(s, r, level)
    s.shot(f"{OUT}/atari_L{level}.png")
    s.wait(0.5)
    static_checks(s, s.save(), level)  # anche dopo che le gocce si sono mosse
    if extra:
        mouth_pass_phase(s, level)
        if model.wall_cols(level):
            push_phase(s, level)
        if level == model.PRESS_LEVEL:
            press_phase(s, level)
        elif OBJECTS[level - 1][3]:
            drop_phase(s, level)
        life_phase(s, level)
        # nel livello delle presse l'unico oggetto fisso e' il piano (con i
        # varchi): il rallentamento si prova negli altri livelli
        if level != model.PRESS_LEVEL:
            slow_sound_phase(s, level)
    sugar_phase(s, level)
    mouth_phase(s, level)
    if extra and level != LEVELS:
        light_phase(s, level)
    return bag_phase(s, level)


BOSS = 7          # BAS: const _Boss (livello segreto della Bocca Gigante)
BOSS_BALLX = 136  # BAS: ultima riga di data objects


def boss_phase(s):
    """Livello segreto: la Bocca Gigante. Sputa, fa male, si batte con 8 colpi."""
    r = s.save()
    check(BOSS, f"dopo il livello {LEVELS} arriva la Bocca Gigante (livello {BOSS})",
          r.v("level") == BOSS and r.flag(0) == 1, f"level={r.v('level')}")
    check(BOSS, "niente zuccherini, chiave gia' presa, luce accesa",
          r.v("choco_bits") == 0xFF and r.flag(2) == 1 and r.flag(4) == 1 and r[SUGARY] in (200, r.v("mouth1y")),
          f"bits={r.v('choco_bits'):08b} flags={r.v('flags'):08b}")
    print("\n".join("     " + x for x in r.pf_rows()))
    check(BOSS, "barra dell'energia piena (8 pixel sul pavimento)", all(r.pf(c, 10) for c in range(12, 20)))
    s.shot(f"{OUT}/atari_boss.png")

    # sputa: lo sputo (missile1) parte dalla bocca
    s.poke({V["hitCooldown"]: 250, PFSCORE1: 0xFF, PLAYER0X: 110, PLAYER0Y: 84,
            V["mouth0x"]: 100, V["mouth0y"]: 40})
    seen = False
    t0 = time.time()
    while time.time() - t0 < 3 and not seen:
        r = s.save()
        seen = r.v("mouth1y") < 200 and r[SUGARY] == r.v("mouth1y")
        s.wait(0.05)
    check(BOSS, "la Bocca Gigante sputa", seen, f"sputo=({r.v('mouth1x')},{r.v('mouth1y')})")
    s.shot(f"{OUT}/atari_boss_sputo.png")

    if not SIXTEEN:
        # sputi mirati al biscotto, in 8 direzioni (0 su, 1 su-destra, 2
        # destra, ... 7 su-sinistra)
        for name, (px, py), d in (("a destra", (120, 30), 2), ("a sinistra", (12, 30), 6),
                                  ("in basso a sinistra", (12, 84), 5), ("in alto a destra", (130, 8), 1),
                                  ("sotto", (64, 84), 4)):
            s.poke({V["hitCooldown"]: 250, PFSCORE1: 0xFF, PFSCORE2: 0xAA, V["mouth0x"]: 50, V["mouth0y"]: 30,
                    V["mouth1y"]: 200, V["spit2y"]: 200, PLAYER0X: px, PLAYER0Y: py})
            t0 = time.time()
            while time.time() - t0 < 2.5:
                r = s.save()
                if r.v("mouth1y") < 200:
                    break
            check(BOSS, f"sputo mirato al biscotto {name}", r.v("mouth1y") < 200 and r.v("spitDir") & 7 == d,
                  f"direzione={r.v('spitDir') & 7} attesa={d} sputo=({r.v('mouth1x')},{r.v('mouth1y')})")
        # dopo il quarto colpo lo sputo si divide in due (direzioni vicine)
        s.poke({V["choco_count"]: 4, V["hitCooldown"]: 250, V["mouth0x"]: 50, V["mouth0y"]: 30,
                V["mouth1y"]: 200, V["spit2y"]: 200, PLAYER0X: 130, PLAYER0Y: 30})
        split = None
        t0 = time.time()
        while time.time() - t0 < 2 and split is None:
            r = s.save()
            if r.v("spit2y") < 200 and r.v("mouth1y") < 200:
                split = r
        if split:
            s.shot(f"{OUT}/atari_boss_sputi.png")
            r = split
        d1, d2 = r.v("spitDir") & 7, (r.v("spitDir") >> 4) & 7
        check(BOSS, "dopo il quarto colpo lo sputo si divide in due",
              split is not None and (d2 - d1) & 7 == 2,
              f"sputi=({r.v('mouth1x')},{r.v('mouth1y')}) ({r.v('spit2x')},{r.v('spit2y')}) direzioni {d1},{d2}")
        s.poke({V["choco_count"]: 0, V["mouth1y"]: 200, V["spit2y"]: 200})

    # lo sputo fa perdere una vita
    s.poke({V["hitCooldown"]: 0, PFSCORE2: 0xAA, PLAYER0X: 110, PLAYER0Y: 84,
            V["mouth0x"]: 20, V["mouth0y"]: 8, V["mouth1x"]: 112, V["mouth1y"]: 76,
            **({} if SIXTEEN else {V["spitDir"]: 4, V["spit2y"]: 200})})
    s.wait(0.4)
    r = s.save()
    check(BOSS, "lo sputo colpisce il biscotto: si perde una vita", r[PFSCORE2] == 0x2A,
          f"vite={r[PFSCORE2]:08b}")

    if not SIXTEEN:
        # colpita: resta ferma dov'e' per un attimo, e intanto un altro colpo
        # non conta; poi riprende a inseguire
        r = s.save()
        s.poke({V["hitCooldown"]: 0, PFSCORE1: 0xFF, PFSCORE2: 0xAA, V["mouth0x"]: 80, V["mouth0y"]: 30,
                V["mouth1y"]: 200, V["spit2y"]: 200, PLAYER0X: 40, PLAYER0Y: 30, V["frame"]: 5,
                V["flags"]: r.v("flags") & ~0xC0})
        s.down("Right", "space")
        s.wait(0.06)
        s.up("Right", "space")
        hit = None
        t0 = time.time()
        while time.time() - t0 < 1.5 and hit is None:
            r = s.save()
            if r.v("choco_count") == 1:
                hit = r
        s.wait(0.1)
        r2 = s.save()
        check(BOSS, "colpita, la Bocca Gigante resta ferma dov'e' (lampeggia)",
              hit is not None and r2.v("hitCooldown") > 0 and
              (r2.v("mouth0x"), r2.v("mouth0y")) == (hit.v("mouth0x"), hit.v("mouth0y")) and hit.v("mouth0x") > 60,
              f"bocca {hit and (hit.v('mouth0x'), hit.v('mouth0y'))} -> ({r2.v('mouth0x')},{r2.v('mouth0y')}) attesa={r2.v('hitCooldown')}")
        # un altro colpo mentre e' ferma non conta
        s.poke({V["hitCooldown"]: 40, V["flags"]: r2.v("flags") & ~0xC0, PLAYER0X: 40, PLAYER0Y: 30})
        s.down("Right", "space")
        s.wait(0.06)
        s.up("Right", "space")
        s.wait(0.4)
        r3 = s.save()
        check(BOSS, "mentre e' ferma un altro colpo non conta", r3.v("choco_count") == 1,
              f"colpi={r3.v('choco_count')}")
        s.wait(0.6)
        r4 = s.save()
        check(BOSS, "poi riprende a inseguire il biscotto",
              (r4.v("mouth0x"), r4.v("mouth0y")) != (r3.v("mouth0x"), r3.v("mouth0y")),
              f"bocca ({r3.v('mouth0x')},{r3.v('mouth0y')}) -> ({r4.v('mouth0x')},{r4.v('mouth0y')})")
        # si riparte da zero colpi (il primo pixel della barra resta spento)
        s.poke({V["choco_count"]: 0})

    # 8 colpi di cioccolatino
    score0 = r.score()
    hits_ok = True
    for k in range(1, 9):
        got = False
        for _ in range(4):
            r = s.save()
            # (la Bocca Gigante appena colpita non si puo' colpire: _hitCooldown a 0)
            s.poke({V["hitCooldown"]: 0, PFSCORE1: 0xFF, PFSCORE2: 0xAA, V["mouth0x"]: 100, V["mouth0y"]: 60,
                    V["mouth1y"]: 200, PLAYER0X: 110, PLAYER0Y: 84, V["flags"]: r.v("flags") & ~0xC0,
                    **({} if SIXTEEN else {V["spit2y"]: 200})})
            s.down("Up", "space")
            s.wait(0.06)
            s.up("Up", "space")
            heard = sfx_seen(s, 0.6)
            r = s.save()
            if r.v("choco_count") == k:
                got = True
                break
        hits_ok &= got
        if not got:
            print(f"     (colpo {k} non andato a segno: count={r.v('choco_count')})")
            break
        if k < 8:
            hits_ok &= (not r.pf(20 - k, 10)) and bool(r.pf(19 - k, 10))
    check(BOSS, "8 colpi di cioccolatino: la barra dell'energia si svuota", hits_ok and not any(r.pf(c, 10) for c in range(12, 20)),
          f"colpi={r.v('choco_count')}")
    check(BOSS, "sconfitta: suono del super potere e +50 a colpo, +500 alla fine",
          SFX["potere"] in heard and r.score() == score0 + 7 * 50 + 550,
          f"effetti={sorted(heard)} punti {score0}->{r.score()}")
    s.wait(0.3)
    r = s.save()
    check(BOSS, "la bocca sparisce e compare il sacchetto",
          r.v("mouth0y") == 200 and r[BALLY] == 28 and r[BALLX] == BOSS_BALLX,
          f"bocca y={r.v('mouth0y')} sacchetto=({r[BALLX]},{r[BALLY]})")
    s.shot(f"{OUT}/atari_boss_sconfitta.png")
    s.poke({PLAYER0X: BOSS_BALLX - 4, PLAYER0Y: 30, V["hitCooldown"]: 250})
    t0 = time.time()
    while time.time() - t0 < 4 and r.v("level") == BOSS:
        s.wait(0.2)
        r = s.save()


def main():
    # --- partita completa dal livello 1 all'ultimo, poi secondo giro ---
    s = Stella(ROM, "test")
    r = s.save()
    check(0, "schermata del titolo", r.flag(0) == 0)
    s.shot(f"{OUT}/atari_titolo.png")
    r = start_level(s, 1)
    for level in range(1, LEVELS + 1):
        r = s.save()
        if r.v("level") != level or r.flag(0) == 0:
            print(f"     (il livello {level} viene avviato dal titolo)")
            s.close()
            s = Stella(ROM, "test")
            start_level(s, level)
        r = play_level(s, level, extra=True)
        s.wait(0.3)
    boss_phase(s)
    if CARD:
        s.wait(OVER + CARD)    # 16K: cartello della vittoria e del livello 1
    r = s.save()
    check(1, f"dopo la Bocca Gigante si riparte dal livello 1 (secondo giro)",
          r.v("level") == 1 and r.v("lap") == 1 and r.flag(0) == 1, f"level={r.v('level')} giro={r.v('lap')}")
    check(1, "nel secondo giro le bocche sono piu' veloci", r.v("speed") == MOUTH_SPEED[0] - 2,
          f"speed={r.v('speed')} (primo giro {MOUTH_SPEED[0]})")
    s.close()

    # --- selezione del livello dal titolo e game over ---
    s = Stella(ROM, "test")
    for level in range(1, LEVELS + 1):
        r = start_level(s, level)
        check(level, f"Select x{level - 1} + Reset parte dal livello {level}", r.v("level") == level)
        s.poke({PFSCORE2: 0x02, V["hitCooldown"]: 0, V["mouth0x"]: r[PLAYER0X], V["mouth0y"]: r[PLAYER0Y],
                V["mouth1x"]: r[PLAYER0X], V["mouth1y"]: r[PLAYER0Y]})
        s.wait(0.5 + OVER)
        r = s.save()
        check(level, "ultima vita persa: game over e ritorno al titolo", r.flag(0) == 0)
        s.wait(0.3)
    r = start_level(s, LEVELS + 1)
    check(1, "il livello segreto non si sceglie con Select (dopo il 6 torna l'1)", r.v("level") == 1)
    # combinazione segreta dal titolo: leva in su + fuoco, poi Reset
    s.poke({PFSCORE2: 0x02, V["hitCooldown"]: 0, V["mouth0x"]: r[PLAYER0X], V["mouth0y"]: r[PLAYER0Y],
            V["mouth1x"]: r[PLAYER0X], V["mouth1y"]: r[PLAYER0Y]})
    s.wait(0.8 + OVER)
    s.down("Up", "space")
    s.wait(0.4)
    r = s.save()
    # (16K: il titolo scrive BOSS! al posto del 7o segnalino; 8K: la gobba
    # sul terreno va al 7o posto, la disegna il kernel del titolo)
    shown = r.v("choco_count") == LEVELS
    check(BOSS, "su + fuoco nel titolo: scelta la Bocca Gigante (7o posto / BOSS!)",
          r.flag(0) == 0 and shown, f"titolo={r.flag(0) == 0} scelta={r.v('choco_count')}")
    s.tap("F2", 0.15)
    s.up("Up", "space")
    s.wait(0.8 + CARD)
    r = s.save()
    check(BOSS, "su + fuoco + Reset: parte la Bocca Gigante", r.v("level") == BOSS and r.flag(0) == 1,
          f"level={r.v('level')}")
    s.close()

    fails = [x for x in RESULTS if not x[2]]
    print(f"\nRISULTATO: {len(RESULTS) - len(fails)}/{len(RESULTS)} controlli superati")
    for f in fails:
        print("  FAIL", f)


if __name__ == "__main__":
    main()
