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


# effetti dimezzati per risparmiare ROM (spazio per le presse del livello 6): si tiene una nota su due e
# la sua durata diventa la somma delle due (stesso andamento, meta' byte)
HALVE = {"explosion", "powerup", "oneup", "pewpew", "gotthecoin", "poof1", "dragit"}


# effetti lunghi dimezzati due volte (spazio per le presse ridisegnate a pezzi)
QUARTER = {"explosion", "oneup", "powerup"}


def halve(notes):
    out = []
    for i in range(0, len(notes), 2):
        vol, ctrl, freq, dur = notes[i]
        if i + 1 < len(notes):
            dur += notes[i + 1][3]
        out.append((vol, ctrl, freq, dur))
    return out


def merge(notes):
    """Note consecutive uguali (stesso volume, timbro e nota) diventano una
    sola nota piu' lunga: il suono non cambia e si risparmiano byte."""
    out = []
    for vol, ctrl, freq, dur in notes:
        if out and out[-1][:3] == (vol, ctrl, freq) and out[-1][3] + dur < 256:
            out[-1] = (vol, ctrl, freq, out[-1][3] + dur)
        else:
            out.append((vol, ctrl, freq, dur))
    return out


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
    w("   ; lettore in assembly: una tabella con l'indirizzo di ogni effetto")
    w("   ; (sfx_lo/sfx_hi, dopo i dati); temp1-temp2 = puntatore all'effetto")
    w("__play_sfx")
    w("   asm")
    for l in """ lda _sfxId
 beq sfx_done
 lda _sfxDur
 beq sfx_next
 dec _sfxDur
 jmp sfx_done
sfx_next
 ldx _sfxId
 lda sfx_lo-1,x
 sta temp1
 lda sfx_hi-1,x
 sta temp2
 ldy _sfxPos
 lda (temp1),y
 cmp #255
 bne sfx_play
 lda #0
 sta _sfxId
 sta AUDV0
 beq sfx_done
sfx_play
 sta AUDC0
 lsr
 lsr
 lsr
 lsr
 sta AUDV0
 iny
 lda (temp1),y
 sta AUDF0
 iny
 lda (temp1),y
 sta _sfxDur
 dec _sfxDur
 iny
 sty _sfxPos
sfx_done""".split("\n"):
        w(l)
    w("end")
    w("   return otherbank")
    w("")
    total = 0
    for sid, key, src, desc in SOUNDS:
        notes = snd[src]
        if src in HALVE:
            notes = halve(notes)
        if src in QUARTER:
            notes = halve(notes)
        notes = merge(notes)
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
    w("   asm")
    w("sfx_lo")
    w(" .byte " + ", ".join(f"<sfx_{key}" for _, key, _, _ in SOUNDS))
    w("sfx_hi")
    w(" .byte " + ", ".join(f">sfx_{key}" for _, key, _, _ in SOUNDS))
    w("end")
    w("")
    sys.stderr.write(f"dati effetti: {total} byte\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
