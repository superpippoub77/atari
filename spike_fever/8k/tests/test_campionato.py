"""Test del campionato (1 PLAYER) di Spike Fever 8K: LEVEL n / VS squadra, vittoria, GAME OVER e ripresa, CHAMPIONS!.

Uso: python3 tests/test_campionato.py sf8k.bin sf8k.sym   (il .sym si ottiene da dasm con -ssf8k.sym)
"""
import sys
sys.path.insert(0, __import__("os").path.dirname(__import__("os").path.abspath(__file__)))
from sim import Sim
s = Sim(sys.argv[1], sys.argv[2])
R = []
def check(name, ok, det=""):
    R.append(ok); print(("  ok   " if ok else "  FAIL ") + name + (f"  ({det})" if det else ""))
s.frames(30)
check("titolo: 1 PLAYER (mode 0)", s['mode'] == 0, s['mode'])
s.tap(); s.frames(5)
lv = lambda: s['mode'] >> 4
check("parte la partita del livello 1 con LEVEL 1", s['demo'] == 0 and lv() == 0 and s['msg'] == 14, f"msg={s['msg']} mode={s['mode']:08b}")
s.frames(105)
check("poi VS CHINA", s['msg'] == 20, f"msg={s['msg']}")
s.frames(70)
check("poi il punteggio", s['msg'] == 0, f"msg={s['msg']}")
# vittoria: 14-0 per la squadra sinistra e punto
def win(team):
    tg = 21 if s['mode'] & 1 else 15
    s['score'] = 0; s[s.sym['score'] + 1] = 0
    s['server'] = team
    s['state'] = 3; s['stateT'] = 0
    s[s.sym['score'] + team] = tg
    s.frames(100)
win(0)
check("vinta: YOU WIN!", s['state'] == 4 and s['msg'] == 13, f"state={s['state']} msg={s['msg']} winner={s['winner']}")
s.frames(260)
check("livello 2: BRAZIL in spiaggia, LEVEL 2", lv() == 1 and s['mode'] & 1 and s['msg'] == 15 and s['score'] == 0,
      f"mode={s['mode']:08b} msg={s['msg']} score={s['score']}")
s.frames(110)
check("VS BRAZIL", s['msg'] == 21, f"msg={s['msg']}")
win(1)
check("persa: GAME OVER", s['state'] == 4 and s['msg'] == 11, f"msg={s['msg']}")
s.frames(30); s.tap()
s.frames(5)
check("col pulsante si rigioca il livello 2", lv() == 1 and s['state'] in (0, 1) and s['msg'] == 15, f"mode={s['mode']:08b} msg={s['msg']} st={s['state']}")
# fino all'ultimo livello
for k in range(4):
    s.frames(250); win(0); s.frames(270)
check("livello 6: USSR", lv() == 5 and s['msg'] in (19, 25), f"mode={s['mode']:08b} msg={s['msg']}")
win(0)
check("vinto il livello 6: CHAMPIONS!", s['msg'] == 12, f"msg={s['msg']}")
s.frames(270)
check("poi il titolo con il livello azzerato", s['mode'] >> 4 == 0 and s['req'] == 0, f"mode={s['mode']:08b}")
check("stack sopra le variabili", s.minsp >= s.sym['RAMEND'] - 1, f"sp min={s.minsp:02X} RAMEND={s.sym['RAMEND']:02X}")
print(f"{sum(R)}/{len(R)}")
