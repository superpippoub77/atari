"""Controlla nel listato di dasm che il codice di un banco non usi etichette (salti, sottoprogrammi, tabelle)
dell'altro banco: i due banchi stanno agli stessi indirizzi ($F000), quindi l'assemblatore non se ne accorge.

Uso: python3 check_banks.py sf8k.lst
"""
import re
import sys

ID = re.compile(r'[A-Za-z_][A-Za-z0-9_]*')
lines = open(sys.argv[1], encoding='latin-1').read().split('\n')
code = False
labels = {}        # etichetta -> banco
uses = []          # (banco, etichetta, riga)
for ln in lines:
    if 'SEG' in ln and 'code' in ln:
        code = True
    m = re.match(r'\s*\d+\s+([0-9a-f]{4})(.*)$', ln)
    if not code or not m:
        continue
    bank = int(m.group(1), 16) >> 12
    body = re.sub(r'^[\t ]*(?:(?:[0-9a-f]{2} )*[0-9a-f]{2}[ *]?)?\t*', '', m.group(2))
    lab = None if body.startswith('      ') else re.match(r' *([A-Za-z_][A-Za-z0-9_]*)(.*)$', body)
    ins = re.match(r' {6}(\S+)\t?(.*)$', body)
    if lab:
        rest = lab.group(2).split(';')[0].split()
        if rest and rest[0] in ('=', 'EQU', 'equ', 'SET'):
            continue
        labels[lab.group(1)] = bank
        ins = re.search(r'\s+(\S+)\t?(.*)$', lab.group(2)) if rest else None
    if ins:
        op, arg = ins.group(1), ins.group(2).split(';')[0]
        if re.fullmatch(r'[a-z]{3}(\.[wb])?|\.byte(\.b)?|\.word(\.w)?|byte|word', op):
            for name in ID.findall(arg):
                uses.append((bank, name, ln.strip()))
bad = [(b, n, l) for b, n, l in uses if n in labels and labels[n] != b and not n.startswith('Start')]
for b, n, l in bad:
    print(f"banco {b} usa {n} (banco {labels[n]}):  {l}")
print(f"{len(labels)} etichette, {len(uses)} usi, {len(bad)} tra banchi diversi")
sys.exit(1 if bad else 0)
