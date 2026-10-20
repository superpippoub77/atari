"""Prova di BLOCK HUNTER 2600 in Stella con i comandi veri (tastiera) e
schermate di titolo e livelli.

Uso: xvfb-run -a python3 tests/test_stella.py ROM CARTELLA_SCHERMATE
"""
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bh  # noqa: E402

rom, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
results = []


def check(name, ok, info=""):
    results.append(ok)
    print(("ok   " if ok else "FAIL ") + name + ("" if ok else f"   {info}"))


s = bh.Stella(rom, "bht")
try:
    time.sleep(1)
    s.grab(f"{out}/titolo.png")
    r = s.save()
    check("titolo", r.v("phase") == 0 and r.pat(0, 0) == bh.FLOOR)
    s.hold(["space"], 0.3)
    time.sleep(3)
    r = s.save()
    check("il pulsante fa partire il livello 1", r.v("phase") == 0 and r.v("level") == 0 and r.pat(0, 0) == bh.WALL,
          (r.v("phase"), r.v("level")))
    check("mappa del livello 1", r.tiles()[3][9] == "o" and r.tiles()[1][6] == ":", r.tiles())
    x0 = r.v("PX")
    s.hold(["Down"], 0.5)
    r = s.save()
    check("la levetta muove il minatore", r.v("PY") > 8, r.v("PY"))
    s.hold(["Right"], 0.4)
    r = s.save()
    check("anche a destra", r.v("PX") > x0, r.v("PX"))
    # dinamite: pulsante con la levetta al centro
    d = r.v("dyn")
    s.tap("space", 0.1)
    time.sleep(0.3)
    r = s.save()
    check("pulsante da fermo: dinamite", r.v("dyn") == d - 1, (d, r.v("dyn")))
    # salto: pulsante con la levetta
    x0 = r.v("PX")
    s.down("Right")
    time.sleep(0.05)
    s.tap("space", 0.1)
    s.up("Right")
    time.sleep(0.2)
    r = s.save()
    check("pulsante con la levetta: salto", r.v("PX") >= x0 + 14, (x0, r.v("PX")))
    s.grab(f"{out}/gioco.png")
    # Reset: nuova partita
    s.tap("F2", 0.2)
    time.sleep(2.5)
    r = s.save()
    check("Reset: nuova partita dal livello 1", r.v("phase") == 0 and r.v("PX") == 8 and r.v("nlives") == 5,
          (r.v("phase"), r.v("PX"), r.v("nlives")))
finally:
    s.close()

# un livello per volta (Select nel titolo)
for n in range(6):
    s = bh.Stella(rom, "bht")
    try:
        time.sleep(0.5)
        s.save()
        for k in range(n):
            s.tap("F1", 0.15)
            time.sleep(0.25)
        s.hold(["space"], 0.3)
        time.sleep(3)
        r = s.save()
        check(f"Select: si parte dal livello {n + 1}", r.v("level") == n and r.v("phase") == 0, r.v("level"))
        s.hold(["Down"], 0.3)
        s.grab(f"{out}/livello{n + 1}.png")
    finally:
        s.close()

print(f"{sum(results)}/{len(results)} ok")
sys.exit(0 if all(results) else 1)
