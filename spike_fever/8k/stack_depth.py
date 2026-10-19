"""Profondità massima dello stack (byte) dalle routine principali: segue jsr (+2) e jmp/salti tra etichette (+0).

Uso: python3 stack_depth.py sf8k.asm bank0.asm logic.asm
"""
import re
import sys

body = {}          # etichetta globale -> [(tipo, destinazione)]
order = []
cur = None
for f in sys.argv[1:]:
    for ln in open(f, encoding='utf-8'):
        code = ln.split(';')[0].rstrip()
        m = re.match(r'([A-Za-z_][A-Za-z0-9_]*)', code)
        if m:
            cur = m.group(1)
            body.setdefault(cur, [])
            order.append(cur)
        if cur is None:
            continue
        t = re.search(r'\b(jsr|jmp|b[a-z]{2})\s+([A-Za-z_][A-Za-z0-9_]*)', code)
        if t:
            body[cur].append(('jsr' if t.group(1) == 'jsr' else 'jmp', t.group(2)))
        if re.search(r'\b(rts|jmp)\b', code) and not re.search(r'\bjmp\s+\.', code):
            body[cur].append(('end', None))
        else:
            body[cur].append(('seq', None))
# un'etichetta senza rts/jmp alla fine prosegue nella successiva
nxt = {a: b for a, b in zip(order, order[1:])}
memo = {}


def depth(lab, stack=()):
    if lab in memo:
        return memo[lab]
    if lab in stack or lab not in body:
        return 0
    best = 0
    falls = True
    for kind, dst in body[lab]:
        if kind == 'jsr':
            best = max(best, 2 + depth(dst, stack + (lab,)))
        elif kind == 'jmp':
            best = max(best, depth(dst, stack + (lab,)))
        if kind == 'end':
            falls = False
        elif kind == 'seq':
            falls = True
    if falls and lab in nxt:
        best = max(best, depth(nxt[lab], stack + (lab,)))
    memo[lab] = best
    return best


roots = ['MainLoop', 'TitleLoop', 'GameEntry', 'B0Entry']
for r in roots:
    print(r, depth(r))


def path(lab, stack=()):
    """percorso più profondo"""
    best, bp = 0, [lab]
    if lab in stack or lab not in body:
        return 0, [lab]
    for kind, dst in body[lab]:
        if kind in ('jsr', 'jmp'):
            d, p = path(dst, stack + (lab,))
            d += 2 if kind == 'jsr' else 0
            if d > best:
                best, bp = d, [lab + (' jsr' if kind == 'jsr' else ' jmp')] + p
    return best, bp


for r in sys.argv[1:] and ['Logic', 'Setup', 'TitleLogic', 'PicSetup']:
    d, p = path(r)
    print(r, d, ' > '.join(p))
