"""Soluzione di Snack 'n' Roll (versione 8K): per ogni livello il percorso piu'
breve che prende gli 8 zuccherini nell'ordine del gioco e arriva al
sacchetto, il punto migliore per il trucco del piano di lavoro e le spinte
dei muri del livello 5. Disegna una mappa per livello con il percorso.

Usa il modello del gioco dei test (tests/model.py): stesse regole di
movimento del BAS, posizioni in pixel di gioco.

Uso:  python3 soluzione.py <cartella di uscita>
      -> mappe livelloN.png e il testo dei passi (soluzione.json)
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "tests"))
import model  # noqa: E402
from model import Grid, build, drop_cells, sugar_xy, sugar_cell, destroy_closure  # noqa: E402

SUGAR = [
    20, 61, 18, 34, 63, 49, 25, 23,
    43, 55, 33, 19, 36, 13, 17, 22,
    45, 57, 39, 27, 42, 21, 17, 15,
    54, 31, 43, 57, 53, 27, 17, 29,
    9, 15, 47, 43, 37, 41, 10, 13,
    57, 63, 51, 19, 53, 31, 25, 29,
]
START = (10, 64)
NAMES = {1: "I tavoli", 2: "Le tazze", 3: "I muri di cioccolato", 4: "Le gocce",
         5: "Il rompicapo dei muri", 6: "Le presse"}
# colori delle righe (pfcolors del BAS) per disegnare le mappe
ROWCOL = {
    "a": ["#4a4a4a", "#ffe066", "#e8e8e8", "#8a6a10", "#a07c18", "#303030",
          "#4a4a4a", "#ffe066", "#e8e8e8", "#8a6a10", "#a07c18"],
    "b": ["#b08a20", "#a07c18", "#8a6a10", "#a07c18", "#8a6a10", "#303030",
          "#b08a20", "#a07c18", "#8a6a10", "#a07c18", "#8a6a10"],
    "c": ["#4a4a4a", "#ffe066", "#8a6a10", "#4a3404", "#8a6a10", "#303030",
          "#4a4a4a", "#ffe066", "#8a6a10", "#4a3404", "#8a6a10"],
}
PALETTE = {1: "a", 2: "a", 3: "b", 4: "b", 5: "c", 6: "b"}


def sugar_goals(mx, my):
    hit = {(dx, dy) for dy in (1, 2, 3) for dx in range(-7, -1)} | {(dx, 0) for dx in (-6, -5, -4, -3)}
    return {(mx + dx, my + dy) for dx, dy in hit}


def ball_goals(bx, by=28):
    return {(x, y) for x in range(bx - 7, bx - 1) for y in range(by - 12, by + 4)}


def where(x, y):
    """posizione a parole (per i passi)."""
    col = (x - 13) // 4
    h = "a sinistra" if col < 11 else ("al centro" if col < 21 else "a destra")
    v = "sopra il piano" if y < 44 else "sotto il piano"
    return f"{v}, {h}"


def route(cells, goals_list, start=START):
    """percorso completo (lista di punti) e lunghezza; None se impossibile."""
    g = Grid(cells)
    pos, total, legs = start, 0, []
    for goals in goals_list:
        p = g.path(pos, goals)
        if p is None:
            return None, None
        legs.append(p)
        total += len(p) - 1
        pos = p[-1]
    return legs, total


def piano_hole(cells, col):
    """il trucco: il cioccolatino colpisce il piano nella colonna col e toglie
    le colonne col-1 .. col+2 della riga 5."""
    return {c for c in cells if not (c[1] == 5 and col - 1 <= c[0] <= col + 2)}


def best_trick(cells, goals_list):
    """prova tutti i punti del piano: dove sparare (dal basso, Su + fuoco) per
    accorciare di piu' il percorso. Ritorna (risparmio, colonna, punto di tiro)."""
    base_legs, base_len = route(cells, goals_list)
    g0 = Grid(cells)
    reach0 = g0.reachable(START)
    best = (0, None, None, base_legs, base_len)
    for col in range(1, 30):
        if (col, 5) not in cells:
            continue
        # punto di tiro: sotto il piano, biscotto con x = 4*col+14 (il
        # cioccolatino parte da x+4), il piu' vicino possibile al piano
        spots = [(4 * col + 14 + dx, y) for dx in range(0, 4) for y in range(48, 62)
                 if (4 * col + 14 + dx, y) in reach0]
        if not spots:
            continue
        spot = min(spots, key=lambda p: p[1])
        holed = piano_hole(cells, col)
        legs, n = route(holed, [{spot}] + goals_list)
        if legs is None:
            continue
        saving = base_len - n
        if saving > best[0]:
            best = (saving, col, spot, legs, n)
    return best


def level_goals(level, sugars):
    bx = model.OBJECTS[level - 1][7]
    return [sugar_goals(*sugar_xy(v)) for v in sugars] + [ball_goals(bx)]


def solve_level(level):
    sugars = SUGAR[(level - 1) * 8:level * 8]
    base = build(level)
    moving = bool(model.OBJECTS[level - 1][3])
    cells = set(base)
    steps = []
    push_notes = []
    if level == 5:
        return solve_level5(level, sugars)
    # oggetti da bucare: zuccherini dentro un blocco distruttibile
    final, destroyed, _ = destroy_closure(cells, level)
    shoot = [v for v in sugars if sugar_cell(v) in destroyed]
    work = set(final)          # con i blocchi bucati
    goals = level_goals(level, sugars)
    saving, col, spot, legs, n = best_trick(work, goals)
    return dict(level=level, sugars=sugars, cells=sorted(base), work=sorted(work), legs=legs,
                length=n, trick=(col, spot, saving), shoot=shoot, moving=moving, pushes=push_notes)


def solve_level5(level, sugars):
    """livello 5: per ogni zuccherino chiuso si cerca UNA spinta di un muro
    che apra la strada (come fa il test), poi si va avanti."""
    walls = list(model.wall_cols(level))
    static = build(level) - model.wall_cells(walls)
    pos = START
    legs, pushes, total = [], [], 0
    bx = model.OBJECTS[level - 1][7]
    targets = [(v, sugar_goals(*sugar_xy(v))) for v in sugars] + [("sacchetto", ball_goals(bx))]
    for v, goals in targets:
        cells = static | model.wall_cells(walls)
        g = Grid(cells)
        p = g.path(pos, goals)
        if p is None:
            reach = g.reachable(pos)
            plan = None
            for wi, d, n, new in model.single_pushes(static, tuple(walls), reach):
                g2 = Grid(static | model.wall_cells(new))
                pushers = model.can_push(reach, walls[wi], d)
                if g2.path(pos, goals) is None or not pushers:
                    continue
                to_push = g.path(pos, pushers)
                if to_push is None:
                    continue
                plan = (wi, d, n, new, to_push)
                break
            assert plan, f"livello 5: nessuna spinta per {v}"
            wi, d, n, new, to_push = plan
            legs.append(to_push)
            total += len(to_push) - 1
            key = walls[wi]
            pushes.append(dict(before=v, wall=key & 127, upper=bool(key & 128),
                               dir="destra" if d == 1 else "sinistra", cols=n,
                               at=to_push[-1]))
            walls = list(new)
            pos = to_push[-1]
            # spingendo il biscotto segue il muro: lo si porta oltre
            cells = static | model.wall_cells(walls)
            g = Grid(cells)
            p = g.path(pos, goals)
            assert p, v
        legs.append(p)
        total += len(p) - 1
        pos = p[-1]
    return dict(level=level, sugars=sugars, cells=sorted(build(level)), work=sorted(static | model.wall_cells(walls)),
                legs=legs, length=total, trick=(None, None, 0), shoot=[], moving=False,
                pushes=pushes, walls_end=walls)


def draw(sol, path_png):
    from PIL import Image, ImageDraw, ImageFont
    S, H = 16, 32
    W = 32 * S
    img = Image.new("RGB", (W + 40, 11 * H + 40), "#101828")
    d = ImageDraw.Draw(img)
    ox, oy = 20, 20
    pal = ROWCOL[PALETTE[sol["level"]]]
    cells = set(map(tuple, sol["cells"]))
    for c, r in cells:
        d.rectangle([ox + c * S, oy + r * H, ox + c * S + S - 1, oy + r * H + H - 1], fill=pal[r])
    # gocce / presse: colonne tratteggiate
    for c, r in drop_cells(sol["level"]):
        if sol["moving"]:
            d.rectangle([ox + c * S + 5, oy + r * H + 4, ox + c * S + S - 6, oy + r * H + H - 5], outline="#c08040")
    # pezzo di piano tolto col trucco
    col, spot, saving = sol["trick"]
    if col is not None:
        for c in range(col - 1, col + 3):
            if (c, 5) in cells:
                d.rectangle([ox + c * S, oy + 5 * H, ox + c * S + S - 1, oy + 5 * H + H - 1],
                            outline="#ff4040", width=3)

    def P(x, y):
        return ox + 4 * (x - 13.5), oy + 4 * (y - 2.5)
    pts = [P(*p) for leg in sol["legs"] for p in leg]
    if len(pts) > 1:
        d.line(pts, fill="#ffe040", width=3)
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 16)
    except OSError:
        font = ImageFont.load_default()
    # partenza
    sx, sy = P(*START)
    d.ellipse([sx - 9, sy - 9, sx + 9, sy + 9], fill="#40c040")
    d.text((sx - 5, sy - 10), "P", fill="black", font=font)
    # zuccherini numerati 1-8 (ordine del gioco)
    for i, v in enumerate(sol["sugars"]):
        c, r = sugar_cell(v)
        cx, cy = ox + c * S + S / 2, oy + r * H + H / 2
        col_fill = "#ffd700" if i == 0 else ("#40c0ff" if i == 1 else "#ffffff")
        d.ellipse([cx - 11, cy - 11, cx + 11, cy + 11], fill=col_fill, outline="black")
        d.text((cx - 5, cy - 10), str(i + 1), fill="black", font=font)
    # sacchetto
    bx = model.OBJECTS[sol["level"] - 1][7]
    x, y = P(bx - 4, 28)
    d.rectangle([x - 12, y - 10, x + 12, y + 10], fill="#ff8040", outline="black")
    d.text((x - 6, y - 10), "S", fill="black", font=font)
    # punto di tiro del trucco
    if spot:
        x, y = P(*spot)
        d.polygon([(x, y - 14), (x - 8, y), (x + 8, y)], fill="#ff4040")
    # spinte dei muri
    for k, pu in enumerate(sol.get("pushes", [])):
        x, y = P(*pu["at"])
        d.text((x - 8, y - 26), f"M{k + 1}", fill="#ff80ff", font=font)
    img.save(path_png)


def moves(leg):
    """percorso -> mosse compresse in quadretti: una colonna = 4 pixel in
    orizzontale, una riga = 8 pixel in verticale."""
    arrows = {(1, 0): "→", (-1, 0): "←", (0, -1): "↑", (0, 1): "↓"}
    runs = []
    for (x0, y0), (x1, y1) in zip(leg, leg[1:]):
        d = (x1 - x0, y1 - y0)
        if runs and runs[-1][0] == d:
            runs[-1][1] += 1
        else:
            runs.append([d, 1])
    out = []
    for d, n in runs:
        q = n / 4 if d[0] else n / 8
        q = max(1, round(q))
        if out and out[-1][0] == arrows[d]:
            out[-1] = (arrows[d], out[-1][1] + q)
        else:
            out.append((arrows[d], q))
    return " ".join(f"{a}{n}" for a, n in out)


def describe(v):
    c, r = sugar_cell(v)
    h = "a sinistra" if c < 11 else ("al centro" if c < 21 else "a destra")
    if r <= 4:
        v_ = "in alto" if r <= 1 else "sopra il piano"
    else:
        v_ = "sotto il piano" if r <= 7 else "in basso"
    return f"{v_}, {h}"


def steps_text(sol):
    """passi a parole per il livello."""
    lv = sol["level"]
    legs = sol["legs"]
    out = []
    i = 0
    col, spot, saving = sol["trick"]
    if col is not None:
        out.append(f"Trucco del piano: vai sotto il piano ({moves(legs[0])}) e spara in alto "
                   f"(Su + fuoco): cade il pezzo sopra di te e si apre la scorciatoia.")
        i = 1
    pushes = {p["before"]: p for p in sol.get("pushes", [])}
    for k, v in enumerate(sol["sugars"]):
        extra = ""
        if v in pushes:
            p = pushes[v]
            where_ = "sul piano" if p["upper"] else "sul pavimento"
            out.append(f"Spinta: raggiungi il muro {where_} della colonna {p['wall']} ({moves(legs[i])}) e "
                       f"spingilo verso {p['dir']} di {p['cols']} colonne camminandoci contro.")
            i += 1
        if v in sol["shoot"]:
            extra = " Lo zuccherino e' dentro un blocco: bucalo prima con un cioccolatino."
        name = "dorato" if k == 0 else ("la chiave" if k == 1 else "")
        mv = moves(legs[i]) or "sei gia' li', lo prendi subito"
        out.append(f"Zuccherino {k + 1}{' (' + name + ')' if name else ''}, {describe(v)}: {mv}.{extra}")
        i += 1
    out.append("Colpisci la Bocca: aspetta che arrivi sulla tua riga (o colonna) e spara verso di lei.")
    out.append(f"Sacchetto: {moves(legs[i])}.")
    return out


def main(out):
    os.makedirs(out, exist_ok=True)
    allsol = {}
    for level in range(1, 7):
        sol = solve_level(level)
        draw(sol, os.path.join(out, f"livello{level}.png"))
        sol.pop("cells")
        sol.pop("work")
        sol["legs"] = [[list(p) for p in leg] for leg in sol["legs"]]
        sol["steps"] = steps_text(sol)
        allsol[level] = sol
        col, spot, saving = sol["trick"]
        print(f"L{level}: percorso {sol['length']} passi, trucco colonna {col} da {spot} "
              f"(risparmio {saving}), da bucare {sol['shoot']}, spinte {sol['pushes']}")
    json.dump(allsol, open(os.path.join(out, "soluzione.json"), "w"), indent=1)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "/tmp/soluzione")
