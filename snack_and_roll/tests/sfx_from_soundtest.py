"""Estrae alcuni effetti dal "bbsoundtest" di batari Basic e genera il codice
del lettore di effetti per il banco 2 di Snack and Roll.bas.

Uso:  python3 sfx_from_soundtest.py <bbsoundtest.bas>  > sfx_bank2.bas

Ogni nota del bbsoundtest e': volume, AUDC, AUDF, durata. Qui viene
compattata in 3 byte: (volume*16 + AUDC), AUDF, durata. 255 = fine.
"""
import re
import sys

# id = priorita': un effetto parte solo se il suo id e' >= di quello in corso
SOUNDS = [
    (1, "shot", "pewpew", "sparo"),
    (2, "push", "dragit", "muro spinto"),
    (3, "slow", "electrobump", "scossa / scivolata (inizio rallentamento)"),
    (4, "block", "poof1", "blocco abbattuto"),
    (5, "sugar", "gotthecoin", "zuccherino preso"),
    (6, "mouth", "explosion", "bocca uccisa"),
    (7, "power", "powerup", "super potere (zuccherino dorato)"),
    (8, "level", "oneup", "cambio livello"),
]


def parse(path):
    src = open(path).read()
    out = {}
    for name, body in re.findall(r'^Init_(\w+)\s*\n\s*sdata\s+sfx_\w+\s*=\s*SoundDataLoc\s*\n(.*?)\n\s*end',
                                 src, re.S | re.M):
        nums = [int(x.replace('$', '0x'), 0) for x in re.findall(r'\$?[0-9A-Fa-f]+', body)]
        notes, i = [], 0
        while i + 3 < len(nums) and nums[i] != 0xFF:
            notes.append(tuple(nums[i:i + 4]))
            i += 4
        out[name] = notes
    return out


def main():
    snd = parse(sys.argv[1])
    lines = []
    w = lines.append
    w("   ;*************************************************************************************************************************")
    w("   ; EFFETTI SONORI (canale 0) - presi dal bbsoundtest di batari Basic")
    w("   ;_________________________________________________________________________________________________________________________")
    w("   ; _sfxId = effetto in corso (0 = nessuno), _sfxPos = posizione nella")
    w("   ; tabella, _sfxDur = frame che mancano alla nota successiva.")
    w("   ; Ogni nota: (volume*16 + AUDC), AUDF, durata. 255 = fine effetto.")
    w("   ; Generato da snack_and_roll/tests/sfx_from_soundtest.py")
    for sid, key, src, desc in SOUNDS:
        w(f"   ;  {sid} = {src:12s} {desc}")
    w("   ;*************************************************************************************************************************")
    w("__play_sfx")
    w("   if !_sfxId then return otherbank")
    w("   if _sfxDur then _sfxDur = _sfxDur - 1 : return otherbank")
    w("   temp6 = _sfxPos")
    labels = " ".join(["__sfx_none"] + [f"__sfx_{key}" for _, key, _, _ in SOUNDS])
    w(f"   on _sfxId goto {labels}")
    w("__sfx_none")
    w("   return otherbank")
    for sid, key, src, desc in SOUNDS:
        w(f"__sfx_{key}")
        w(f"   temp1 = sfx_{key}[temp6] : temp6 = temp6 + 1")
        w(f"   temp2 = sfx_{key}[temp6] : temp6 = temp6 + 1")
        w(f"   temp3 = sfx_{key}[temp6]")
        w("   goto __sfx_note")
    w("__sfx_note")
    w("   if temp1 = 255 then _sfxId = 0 : AUDV0 = 0 : return otherbank")
    w("   AUDV0 = temp1 / 16 : AUDC0 = temp1 & 15 : AUDF0 = temp2")
    w("   _sfxDur = temp3 - 1")
    w("   _sfxPos = _sfxPos + 3")
    w("   return otherbank")
    w("")
    total = 0
    for sid, key, src, desc in SOUNDS:
        notes = snd[src]
        data = []
        for vol, ctrl, freq, dur in notes:
            b = (vol & 15) * 16 + (ctrl & 15)
            assert b != 255, f"{src}: nota che coincide col terminatore"
            data += [b, freq & 255, max(1, dur)]
        data.append(255)
        assert len(data) <= 256, src
        total += len(data)
        w(f"   ; {src} ({len(notes)} note) - {desc}")
        w(f"   data sfx_{key}")
        for i in range(0, len(data), 18):
            w("   " + ", ".join(str(x) for x in data[i:i + 18]))
        w("end")
        w("")
    sys.stderr.write(f"dati effetti: {total} byte\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
