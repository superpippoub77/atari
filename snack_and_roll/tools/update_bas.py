"""Rigenera le parti di "Snack and Roll 16K.bas" comprese tra i marcatori
   ; >>> generato da tools/<script> [argomenti]
   ; <<< fine
eseguendo lo script indicato. Uso:  python3 tools/update_bas.py
"""
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BAS = os.path.join(HERE, "..", "Snack and Roll 16K.bas")

src = open(BAS).read()
pat = re.compile(r"(   ; >>> generato da tools/(\S+)([^\n]*)\n)(.*?)(   ; <<< fine\n)", re.S)


def fill(m):
    script, args = m.group(2), m.group(3).split()
    out = subprocess.run([sys.executable, os.path.join(HERE, script), *args],
                         capture_output=True, text=True, check=True).stdout
    return m.group(1) + out.rstrip("\n") + "\n" + m.group(5)


new, n = pat.subn(fill, src)
open(BAS, "w").write(new)
print(f"{n} sezioni rigenerate")
