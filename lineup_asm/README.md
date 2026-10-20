# LineUp! 2600 (Assembly)

Versione prototipo di **LineUp!** scritta in **assembly 6502** per Atari 2600.

## Stato attuale

Questo build implementa il core loop:

- gioco a tempo con vite;
- selezione righe con joystick su/giù;
- selezione coppie con fire;
- coppie corrette rimosse, errore = perdita vita;
- progressione livello 1..100;
- distrattore aggiunto durante il round;
- shuffle delle righe durante il round;
- +1 vita periodica (cap a 3).

## Comandi

- **Su/Giù**: cursore
- **Fire**:
  - nel titolo: start
  - in gioco: selezione / conferma coppia
  - in game over: ritorna al titolo

## Build locale

Da questa cartella:

```bash
npm install
npm run build
```

Output:

- [`LineUp.bin`](./LineUp.bin) (ROM 4K)

## Test online (Javatari)

La ROM pubblicata per il menu web principale è:

- [`../release/lineup/LineUpASM.bin`](../release/lineup/LineUpASM.bin)

e si avvia da [`../index.html`](../index.html) selezionando **LineUp! ASM**.
