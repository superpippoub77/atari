# Test della ROM Atari 2600

Test automatico di `Snack and Roll.bas` compilato. Gira nell'emulatore Stella e gioca una partita
vera, premendo i tasti come un giocatore.

## Requisiti

- [Stella](https://stella-emu.github.io/) 6.x
- `xdotool`, ImageMagick (`import`), `xvfb-run` (display virtuale)
- Python 3

Su Ubuntu/Debian: `sudo apt install stella xdotool imagemagick xvfb`

## Uso

```bash
cd snack_and_roll/tests
xvfb-run -a -s "-screen 0 800x600x24" python3 test_all.py . "../bin/Snack and Roll.bas.bin" /tmp/screenshot
```

Dura circa 25 minuti e salva gli screenshot di ogni livello nella cartella indicata.

## Come funziona

- `snr.py` avvia Stella e preme i tasti con `xdotool`. Per leggere la RAM salva lo stato (F9).
  Per spostare personaggi o impostare situazioni modifica la RAM nello stato e lo ricarica (F11).
- `model.py` è un modello Python del caricamento dei livelli e delle regole di movimento del BAS.
  Serve a calcolare i percorsi e a verificare che ogni zuccherino e ogni sacchetto sia raggiungibile.
- `test_all.py` gioca una partita completa dal livello 1 alla vittoria. Per ogni livello controlla:
  - nessun oggetto sospeso nel vuoto: tutto poggia sul piano di lavoro o sul pavimento, oppure è appeso al soffitto o al piano;
  - le gocce: un solo pixel che scende, senza residui;
  - gli zuccherini: compaiono uno alla volta e restano fermi, nessuno cade dentro un oggetto, tutti si raccolgono camminando, nessuno viene contato due volte;
  - lo zuccherino dorato congela le bocche e lo zuccherino 1 dà la chiave;
  - il cioccolatino lanciato con direzione e fuoco premuti insieme colpisce la bocca: +10, una volta sola;
  - il sacchetto compare solo alle condizioni giuste, si raggiunge e porta al livello successivo;
  - la luce si spegne dopo 32 secondi e si riaccende sparando sul piano di lavoro;
  - la barra del tempo, le vite e il game over;
  - la selezione del livello con Select;
  - al livello 5, il muro spingibile: si sposta spingendolo con la levetta, si ferma a fine corsia e non si distrugge.
