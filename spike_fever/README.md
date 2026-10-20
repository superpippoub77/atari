# SPIKE FEVER 2600

> Copiato dalla cartella `atari2600/` della repository [superpippoub77/spikeball](https://github.com/superpippoub77/spikeball), dove c'è anche la versione completa per il browser. Si gioca anche dalla pagina principale di questa repo ([`../index.html`](../index.html), pulsanti *Spike Fever*).

Versione per **Atari 2600 (VCS)** di Spike Fever in stile **Power Spikes**: 2 contro 2, **cartuccia da 16K** (bank switching F6), scritta in assembly 6502.
- **Nel browser**: [`index.html`](index.html), con l'emulatore Javatari.js.
- **Fuori dal browser**: scarica `spikefever2600.bin` per Stella, un altro emulatore o un Atari vero con una cartuccia flash che supporta F6 (16K).

> **Perché 16K e non 4K?** La prima versione da 4K era già piena (4096 byte su 4096). Livelli, paesaggi, beach volley, tutte le mosse di Power Spikes, la scelta della nazionale e la schermata del titolo occupano circa 11K, quindi serve una cartuccia da 16K. È il formato dei giochi 2600 più ricchi e funziona su emulatori e cartucce flash.

## Versione 4K: 4 contro 4 (cartella [`4k/`](4k/))
Accanto alla 16K c'è la cartuccia da **4K**, giocabile da [`4k/index.html`](4k/index.html), con **4 giocatori per squadra come in Power Spikes**.
- **Prima linea**: centrale, alzatore e schiacciatore sono lo stesso sprite ripetuto 3 volte dall'hardware (copie NUSIZ a 16 pixel). Insieme fanno il **muro a tre** e saltano insieme in attacco, come nelle combinazioni di Power Spikes.
- **Difensore**: è disegnato da solo, riceve, batte e attacca dalla seconda linea.
- **Alternanza**: le due linee si alternano a 30 Hz. La palla è sempre disegnata con il missile dello sprite che in quel fotogramma mostra un giocatore solo; il segno di caduta è l'oggetto *ball* del TIA.
- **Alzate**: GIÙ = primo tempo del centrale (veloce, si mura una volta su due), verso il fondo = seconda linea del difensore, niente = palla alta allo schiacciatore.
- **GAME SELECT**: scorre 8 combinazioni. In alto a sinistra compare il numero di persone (**1** contro il computer, **2** uno contro l'altro), a destra i giocatori per squadra (**4** o **2**). Lo sfondo mostra l'arena: palazzetto (set a 15) o spiaggia (set a 21).
- **2 contro 2**: in prima linea c'è solo l'alzatore (al posto del palleggio). Il difensore riceve, poi attacca a rete sull'alzata, come nel beach.
- **Difficoltà**: le due levette danno 4 livelli del computer. **B B** = 1 (facile), **sinistra A** = 2, **destra A** = 3, **A A** = 4 (il più forte). A ogni livello il computer sbaglia la metà in ricezione e mura più spesso.
- **Comandi**: gli stessi della 16K, senza i menu.
- **Compilazione**: `cd 4k && python3 gen_data.py > data.inc && node build.js` crea `sf4k.bin`, che occupa esattamente 4096 byte. Per farci stare tutto, le tabelle delle arene si sovrappongono dove coincidono. Contano anche i bit che il TIA ignora: il bit 0 dei colori e il nibble basso di PF0.

## Versione 8K: la 4K allargata (cartella [`8k/`](8k/))
La cartuccia da **8K** (bankswitching F8, NTSC), giocabile da [`8k/index.html`](8k/index.html), è la 4K con un banco in più. Il banco 0 contiene il titolo e la logica della partita, il banco 1 il kernel e i giocatori.
- **Titolo**: logo grande SPIKE / FEVER sfumato dal giallo al rosso (come la 16K). Sotto c'è un quadro animato: lo schiacciatore rincorre, salta e schiaccia, il muro salta contro di lui e la palla rotola. Il menu mostra la modalità scelta con GAME SELECT (persone, giocatori per squadra, arena) e PUSH FIRE lampeggia. Il pulsante o GAME RESET fa partire la partita; dopo una decina di secondi parte la dimostrazione.
- **Modalità** (GAME SELECT): **1 PLAYER WORLD CUP** (campionato), **1 PLAYER BEACH** (partita singola 2 contro 2 sulla sabbia contro il computer), **2 PLAYERS** al palazzetto 4 contro 4 o 2 contro 2, e in spiaggia. In spiaggia si gioca sempre **2 contro 2**, come nel beach volley vero.
- **Campionato (WORLD CUP)**: in **1 PLAYER** affronti 6 nazionali in fila, come nella 16K (4 contro 4 al palazzetto, 2 contro 2 nei livelli in spiaggia).

  | Livello | Avversario | Arena | Computer (almeno) |
  |---|---|---|---|
  | 1 | CHINA | palazzetto | livello 1 |
  | 2 | BRAZIL | spiaggia | livello 2 |
  | 3 | USA | palazzetto | livello 2 |
  | 4 | CUBA | spiaggia | livello 3 |
  | 5 | JAPAN | palazzetto | livello 3 |
  | 6 | USSR | palazzetto | livello 4 |

  - Ogni nazionale ha i suoi colori di maglia.
  - A inizio partita compaiono **LEVEL n** e **VS** con il nome della squadra.
  - Se vinci compare **YOU WIN!** e si passa al livello successivo (subito col pulsante, o dopo qualche secondo).
  - Se perdi compare **GAME OVER**: col pulsante rigiochi lo stesso livello (CONTINUE), altrimenti si torna al titolo.
  - Vinto il sesto livello, sei **CHAMPIONS!**
  - Il computer è forte almeno quanto il livello; le levette di difficoltà possono solo renderlo più forte.
  - GAME RESET riparte dal livello 1. Nel menu WORLD CUP compare al posto dell'arena: l'arena la sceglie il livello.
- **Scritte in inglese**: il menu (1 PLAYER, 4 VS 4, INDOOR / BEACH, WORLD CUP, PUSH FIRE). In partita, per un secondo al posto del punteggio, ci sono gli annunci come lo speaker del gioco completo: **SPIKE!**, **POWER HIT!**, **QUICK!**, **BACK SPIKE**, **DINK!**, **BLOCK!**, **NET!**, **OUT!**, **ACE!**, **GAME SET**.
- **Il joystick passa da un giocatore all'altro**: comandi sempre chi deve toccare la palla. In battuta e in ricezione il difensore; dopo il bagher il controllo passa all'alzatore, che va portato sotto la palla (se è lontano più di 10 pixel l'alzata non riesce e la palla cade); poi chi schiaccia, e quando attaccano gli avversari la prima linea (muro). Il giocatore comandato ha la **maglia rossa**; la tua squadra è bianca al palazzetto e gialla in spiaggia.
- **L'alzatore del computer corre sotto la palla**: dopo la ricezione l'alzatore va dove arriva il bagher e palleggia lì (prima restava fermo al suo posto). Nel 4 contro 4 si sposta tutta la prima linea, senza passare la rete: centrale, alzatore e schiacciatore sono lo stesso sprite ripetuto 3 volte dal TIA, quindi si muovono e cambiano posa insieme. L'alzata segue lo spostamento, così la palla arriva sulle mani di chi attacca; dopo l'attacco la linea torna al suo posto.
- **Più pose**:
  - corsa a 4 passi;
  - salto con le braccia su e caduta a gambe raccolte;
  - schiacciata con il seguito del colpo;
  - palleggio dell'alzatore;
  - muro con le braccia alte.
- **Fisica del gioco completo** (dalla repository spikeball, `match.js`):
  - **Rimbalzi**: la palla a terra rimbalza (velocità verticale × 0,44, orizzontale × 0,63, come lo 0,45 / 0,6 dell'originale) e rotola finché si ferma, anche dopo il punto.
  - **Rete**: smorza la palla (vx × −0,19, vy × 0,31 se scende) invece di respingerla sempre allo stesso modo.
  - **Qualità della schiacciata**: dipende dal tempo. In perfetto tempo la schiacciata è potente (arriva in metà tempo). Al limite della finestra, una volta su due finisce in rete. Anche il computer ogni tanto schiaccia forte.
  - **Ricezione del computer** (la penalità di velocità dell'originale): sulle palle veloci il suo errore di piazzamento cresce del 50%.
- **Compilazione**: `cd 8k && python3 gen_data.py && node build.js`. `gen_data.py` scrive `data.inc`, `title.inc` e `msgs.inc` (le scritte della partita); il risultato è `sf8k.bin`, 8192 byte.
- **Controlli**:
  - `python3 check_banks.py sf8k.lst` controlla che nessun banco usi etichette dell'altro (i due banchi stanno agli stessi indirizzi, quindi dasm non se ne accorge);
  - `python3 stack_depth.py sf8k.asm bank0.asm logic.asm` misura la profondità delle chiamate (lo stack ha 10 byte);
  - `python3 tests/test_campionato.py sf8k.bin sf8k.sym` gioca il campionato in un emulatore minimo (py65) e controlla scritte, livelli, GAME OVER con ripresa, CHAMPIONS! e stack.

## Modalità (versione 16K)
- **1 PLAYER**: scegli la tua nazionale tra 10 (Italia, Francia, Germania, Spagna, Brasile, USA, Giappone, Cina, Cuba, URSS), poi affronti 6 livelli.

  | Livello | Avversario | Paesaggio |
  |---|---|---|
  | 1 | Cina | Palestra di Pechino: parquet, spalliere, finestre, travi |
  | 2 | Brasile | **Beach volley** a Copacabana: sabbia, mare, Pan di Zucchero, palme, sole |
  | 3 | USA | LA Arena: campo blu, cartelloni, pubblico, riflettori |
  | 4 | Cuba | **Beach volley** ai Caraibi al tramonto: sole sull'orizzonte, palme in controluce, gabbiani |
  | 5 | Giappone | Campo all'aperto sotto il monte Fuji innevato |
  | 6 | URSS | Finale a Mosca: arena rossa, stendardi, pubblico |

  - Se perdi, compare **GAME OVER / CONTINUE?**: premi il pulsante per rigiocare lo stesso livello.
  - Se vinci tutto, sei **CHAMPION!**
  - Il computer migliora a ogni livello.
- **2 PLAYERS**: ognuno sceglie la nazionale col proprio joystick, poi si sceglie l'arena.
- **Dimostrazione**: dopo qualche secondo nel titolo parte una partita tra due squadre del computer.
- **Set**: a 11 punti nelle arene, a 15 sulla sabbia, con 2 punti di scarto.

## Come si gioca (tutte le mosse di Power Spikes)
Ogni squadra ha un **alzatore** (vicino alla rete) e un **attaccante/ricevitore**.

| Momento | Comando |
|---|---|
| **Battuta** | Pulsante = lancio. Al lancio: **su** = battuta altissima (*towering*, esce dallo schermo), **verso la rete** = battuta in salto con rincorsa, niente = normale. Premi di nuovo quando la palla è **rossa**; al colpo verso la rete = corta, verso il fondo = lunga |
| **Ricezione** | Porta il ricevitore sul **segno giallo**. Se la palla è troppo lontana premi il pulsante: **tuffo** |
| **Alzata** | **giù** = primo tempo (veloce, difficile da murare); **verso il fondo** = attacco di seconda linea; **verso la rete + pulsante** = palleggio di seconda dell'alzatore (attacco a sorpresa); niente = palla alta |
| **Attacco** | Rincorsa e stacco automatici; premi quando la palla è **rossa**. **su** = pallonetto, **giù** = schiacciata potente (rompe il muro, ma se sbagli il tempo va fuori), verso la rete = corta, verso il fondo = lunga. Fuori tempo = palla lenta; se non premi, palla facile per gli avversari |
| **Muro** | Quando attaccano gli avversari premi il pulsante: salta il tuo alzatore. Il primo tempo e la seconda linea si murano meno |

Battute speciali e schiacciate potenti rendono la ricezione più difficile.

Console: **GAME RESET** = titolo; **GAME SELECT** (nel titolo) = 1 o 2 giocatori; **difficoltà destra A** = il computer sbaglia meno in ricezione.
Tasti in Javatari: frecce + spazio = joystick 1; F12 = RESET, F11 = SELECT, F9 = difficoltà destra.

## Come è fatta la cartuccia
| Banco | Contenuto |
|---|---|
| 0 | Ciclo principale, logica della partita e dei menu, intelligenza del computer |
| 1 | Kernel della partita, sprite, colori di 10 nazionali (scarpe o piedi nudi), 6 arene |
| 2 | Kernel delle schermate: titolo, scelta, presentazione, game over, campione; scritte e bandiere |
| 3 | Libero (per altre arene o livelli) |

- **Cambio di banco**: piccoli "stub" agli stessi indirizzi in tutti i banchi ($FFC0-$FFE5). Leggere $1FF6/$1FF7/$1FF8 seleziona il banco 0/1/2.
- **Kernel della partita**: area di gioco a 2 righe. Per ogni coppia di righe:
  - colore di fondo, PF0, PF1, PF2 e colore del playfield dell'arena;
  - giocatore sinistro e destro con un colore diverso per ogni riga;
  - palla (missile 1, rossa quando bisogna colpire) e segno di caduta (missile 0).

  I due compagni di squadra si alternano a ogni fotogramma (30 Hz).
- **Titolo come Power Spikes**: logo **SPIKE FEVER** grande in playfield asimmetrico, sfumato dal giallo al rosso. Sotto c'è un quadro con la schiacciata contro il muro a sprite doppi, poi il menu.
- **Scritte**: playfield asimmetrico (10 caratteri 3x5). **Bandiere**: playfield riflesso in modo SCORE, così i tricolori verticali hanno 3 colori per riga.
- **Tempi controllati** con un emulatore 6502 (`py65` + bank switching), su oltre 45.000 fotogrammi di partita giocata da un "bot" che usa tutte le mosse:
  - ogni schermata e ogni fotogramma di gioco: 262 righe NTSC esatte;
  - logica: VBLANK al massimo 2499 cicli su 2880, overscan 1527 su 2240.

## Compilare
```sh
npm install dasm              # assemblatore dasm (versione JavaScript)
python3 gen_data.py           # -> bank0.inc, bank1.inc, bank2.inc (grafica, arene, bandiere, scritte)
node build.js                 # -> spikefever2600.bin (16384 byte)
```

| File | Contenuto |
|---|---|
| `spikefever2600.asm` | programma completo, commentato |
| `gen_data.py` | giocatori, colori delle nazionali, arene, bandiere, scritte e logo: si modificano qui |
| `bank*.inc` | tabelle generate (non modificare a mano) |
| `index.html` | pagina per giocare nel browser |
| `../emulator/javatari.js`, `../emulator/license.txt` | emulatore [Javatari.js](https://github.com/ppeccin/javatari.js) di Paulo Peccin (licenza AGPL v3), non modificato, condiviso con gli altri giochi della repo |
