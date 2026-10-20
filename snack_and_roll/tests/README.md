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

Per la versione 16K (cartelli ad alta risoluzione che fermano il gioco per qualche secondo) si indicano i secondi da aspettare:

```bash
SNR_CARD=2.5 SNR_OVER=3.4 xvfb-run -a -s "-screen 0 800x600x24" python3 test_all.py . "../bin16/Snack and Roll 16K.bas.bin" /tmp/screenshot
```

`SNR_CARD` è il cartello di inizio livello, `SNR_OVER` il GAME OVER e la vittoria. La stessa variabile vale per `test_features.py`.

## Come funziona

- `snr.py` avvia Stella e preme i tasti con `xdotool`. Per leggere la RAM salva lo stato (F9).
  Per spostare personaggi o impostare situazioni modifica la RAM nello stato e lo ricarica (F11).
- `model.py` è un modello Python del caricamento dei livelli e delle regole di movimento del BAS.
  Serve a calcolare i percorsi e a verificare che ogni zuccherino e ogni sacchetto sia raggiungibile.
- `sugar_layout.py` calcola e verifica la disposizione degli zuccherini (`data sugar`). Simula i colpi di cioccolatino per sapere quali oggetti il giocatore riesce davvero a bucare. Poi sceglie uno zuccherino per sezione: fuori dagli oggetti indistruttibili, oppure dentro la riga distruttibile di una tazza o di un muro di cioccolato. `python3 sugar_layout.py` verifica la tabella del BAS con queste regole (`--genera` stampa la vecchia disposizione calcolata solo con le regole).
- `../tools/sugar_opt.py` sceglie posizioni e ordine degli zuccherini dentro le regole: per ogni livello simula 2000 partite di un giocatore medio (pause, tempi di reazione, blocchi da bucare, spari alle bocche allineate, luce che si spegne e si riaccende) con le bocche che inseguono come nel BAS, e cerca tratti equilibrati e una probabilità di essere morsi che cresce con il livello. `--write` scrive la tabella nel BAS.
- `sfx_from_soundtest.py` estrae gli effetti scelti dal *bbsoundtest* di batari Basic e genera il lettore di effetti del banco 2 (`python3 sfx_from_soundtest.py bbsoundtest.bas`). Il lettore degli effetti è in assembly (una tabella con l'indirizzo di ogni effetto). Per risparmiare ROM unisce le note consecutive uguali (senza cambiare il suono), dimezza gli effetti (una nota su due, durata doppia) e dimezza due volte i tre più lunghi (esplosione, super potere, cambio livello): lo spazio serve alle presse del livello 6.
- `test_features.py` (circa 1 minuto) prova le novità di giocabilità: fuga finale (bocche e musica al doppio), tempo in scadenza (musica veloce, barra rossa), bonus tempo a fine livello, fine del super potere, combo "partita perfetta" (zuccherino doppio senza vite perse) e levette di difficoltà (in A: Bocche più veloci, 6 tacche, niente bonus; in B: normale). Si lancia come `test_all.py`.
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
  - il trucco del piano: il primo colpo toglie un pezzo di piano (al massimo 4 colonne vicine), un secondo colpo riaccende la luce ma non toglie altri pezzi;
  - la barra del tempo, le vite e il game over;
  - la selezione del livello con Select;
  - le presse del livello 6: stantuffi a T (perno continuo, testa larga in fondo) che si allungano e si ritirano; scendendo sul biscotto lo schiacciano (una vita), stando fermi a contatto col piano non succede niente; nei percorsi del test le presse si attraversano aspettando che risalgano;
  - i muri spingibili (5 al livello 5, sopra e sotto il piano; anche piu' spinte di fila per aprire la strada): si spostano spingendoli con la levetta nei due sensi, si fermano a fine corsia, non si distruggono e schiacciano le bocche; alla fine tornano al loro posto;
  - livello 5: gli zuccherini delle stanze chiuse non si raggiungono senza spingere un muro; il test trova la spinta giusta (`model.single_pushes`) e la esegue con la levetta;
  - una bocca uccisa (con un cioccolatino o schiacciata) sparisce e ricompare nel suo angolo dopo circa 4 secondi;
  - dopo il livello 6 arriva la Bocca Gigante: sputa mirando al biscotto (8 direzioni), dopo il quarto colpo lo sputo si divide in due, lo sputo toglie una vita, colpita resta ferma un attimo e intanto non si colpisce di nuovo, 8 colpi svuotano la barra dell'energia, alla sconfitta compare il sacchetto (+50 a colpo, +500 alla fine); non si sceglie con Select;
  - dopo la Bocca Gigante si riparte dal livello 1 con le bocche più veloci.
