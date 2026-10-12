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
- `sugar_layout.py` calcola e verifica la disposizione degli zuccherini (`data sugar`). Simula i colpi di cioccolatino per sapere quali oggetti il giocatore riesce davvero a bucare. Poi sceglie uno zuccherino per sezione: fuori dagli oggetti indistruttibili, oppure dentro la riga distruttibile di una tazza o di un muro di cioccolato. Da lanciare con `python3 sugar_layout.py`; stampa le mappe e la tabella per il BAS.
- `sfx_from_soundtest.py` estrae gli effetti scelti dal *bbsoundtest* di batari Basic e genera il lettore di effetti del banco 2 (`python3 sfx_from_soundtest.py bbsoundtest.bas`). Per risparmiare ROM unisce le note consecutive uguali (senza cambiare il suono) e dimezza i tre effetti più lunghi (esplosione, super potere, cambio livello).
- `test_features.py` (circa 1 minuto) prova le novità di giocabilità: fuga finale (bocche e musica al doppio), tempo in scadenza (musica veloce, barra rossa), bonus tempo a fine livello, fine del super potere e combo "partita perfetta" (zuccherino doppio senza vite perse). Si lancia come `test_all.py`.
- `test_all.py` gioca una partita completa sui 6 livelli e sul livello segreto della Bocca Gigante, fino all'inizio del secondo giro. Per ogni livello controlla:
  - nessun oggetto sospeso nel vuoto: tutto poggia sul piano di lavoro o sul pavimento, oppure è appeso al soffitto o al piano;
  - le gocce: un solo pixel che scende, senza residui;
  - gli zuccherini: uno per sezione, compaiono uno alla volta e restano fermi, ognuno è fuori dagli oggetti indistruttibili o dentro uno distruttibile; tutti si raccolgono (il test buca gli oggetti a colpi di cioccolatino quando serve); nessuno viene contato due volte;
  - lo zuccherino dorato congela le bocche e lo zuccherino 1 dà la chiave;
  - gli effetti sonori partono al momento giusto (sparo, zuccherino, super potere, blocco, bocca, scossa, muro, cambio livello);
  - la bocca passa sopra a qualsiasi oggetto, in tutti i livelli;
  - il cioccolatino lanciato con direzione e fuoco premuti insieme colpisce la bocca: +10, una volta sola;
  - il sacchetto compare solo alle condizioni giuste, si raggiunge e porta al livello successivo;
  - la luce si spegne dopo 32 secondi e si riaccende sparando sul piano di lavoro;
  - la barra del tempo, le vite e il game over;
  - la selezione del livello con Select;
  - i muri spingibili (3 al livello 5, 1 al livello 6): si spostano spingendoli con la levetta nei due sensi, si fermano a fine corsia, non si distruggono e schiacciano le bocche; alla fine tornano al loro posto;
  - livello 5: gli zuccherini delle stanze chiuse non si raggiungono senza spingere un muro; il test trova la spinta giusta (`model.single_pushes`) e la esegue con la levetta;
  - una bocca uccisa (con un cioccolatino o schiacciata) sparisce e ricompare nel suo angolo dopo circa 4 secondi;
  - dopo il livello 6 arriva la Bocca Gigante: sputa, lo sputo toglie una vita, 8 colpi svuotano la barra dell'energia, alla sconfitta compare il sacchetto (+50 a colpo, +500 alla fine); non si sceglie con Select;
  - dopo la Bocca Gigante si riparte dal livello 1 con le bocche più veloci.
