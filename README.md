# 📘 SNACK 'N' ROLL™  
*Per Atari® 2600*  
**Programma di:** Filippo Morano

---

> 🎮 **Novità:** c'è anche la versione **Godot 4**, un platform 2D a scorrimento orizzontale con effetti e trabocchetti in più.
> Si trova in [`snack_and_roll_godot/`](snack_and_roll_godot/README.md).
>
> 📦 **Download** (Atari 2600 `.bin`, Windows, Linux, Android, Browser): cartella [`release/`](release/README.md).

> 🛡️ **Nuovo gioco:** [*Circular Defense*](circular_defense/README.md) per Atari 2600. Difendi 6 città con il paddle (o col joystick) in 8 livelli.
>
> 🍪 **Versione 16K:** [`Snack and Roll 16K.bas`](snack_and_roll/Snack%20and%20Roll%2016K.bas), cartuccia da 16K con bankswitching F6, stessa partita della 8K con una grafica più ricca:
> - titolo ad alta risoluzione: logo *SNACK 'N' ROLL* sfumato (le due L si piegano come alberi), scritta del livello scelto, biscotto con le gocce di cioccolato che gira, pavimento a scacchi;
> - cartello di inizio livello con il numero grande e il nome dello schema, e la sua fanfara;
> - schermate di **GAME OVER** (con il biscotto morsicato) e di vittoria sulla Bocca Gigante (*HAI VINTO! BRAVO*);
> - in gioco, una parete colorata diversa per ogni livello, il piano di lavoro chiaro e il punteggio ben leggibile.
>
> Le scritte e i disegni ad alta risoluzione usano la tecnica dello "sprite a 48 pixel", con una routine in assembly generata da [`snack_and_roll/tools/gen_hires.py`](snack_and_roll/tools/gen_hires.py).

---

> 🔧 **Versione Atari aggiornata**
> - Gli zuccherini compaiono uno alla volta, fermi, senza sfarfallio.
> - Gli oggetti della parte alta poggiano sempre sul piano di lavoro; lampade, gocce e cioccolato della parte bassa sono appesi al piano.
> - **6 livelli a tema**: 1 tavoli, 2 tazze, 3 muri di cioccolato, 4 gocce (solo gocce: 8, una per sezione, che scendono fino al piano o al pavimento), 5 muri mobili, 6 **presse** (al buio). Dopo il livello 6 c'è il **livello segreto della Bocca Gigante** (vedi sotto), poi si riparte dal primo con le bocche più veloci (un giro in più), finché ci sono vite.
> - I muri mobili si spostano quando il biscotto li spinge e **schiacciano le bocche** (+10, conta come bocca colpita).
> - **Livello 5, il rompicapo dei muri**: ci sono muri mobili **sia sopra sia sotto il piano**. Quello di sopra poggia sul piano sotto una lampada appesa al soffitto; i due di sotto stanno sul pavimento sotto una lampada appesa al piano. Ogni muro con la sua lampada chiude la colonna, e sparando non si passa (muri e lampade sopra i muri non si rompono). Tutta la metà destra dello schermo si raggiunge solo spingendo un muro: quello sopra il piano, oppure il primo muro di sotto e poi il secondo. Tra i due muri di sotto c'è una stanza chiusa, con uno zuccherino. Nessuna combinazione di spinte chiude per sempre uno zuccherino.
> - Bocche più lente, che passano sopra a qualsiasi oggetto. Una bocca uccisa ricompare nel suo angolo dopo circa 4 secondi.
> - Schermata iniziale: il biscotto, inseguito dalla bocca, scorre in continuo entrando sempre da destra; le due "l" di *Roll* sventolano.
> - Gocce e presse si muovono con calma (un passo ogni 16 fotogrammi) e si ridisegnano una per fotogramma, così lo schermo resta sempre stabile a 312 righe (PAL).
> - **Audio**: tema iniziale rock'n'roll originale (giro di boogie in Do), musica leggera di sottofondo ed effetti presi dal *bbsoundtest* di batari Basic (sparo, zuccherino, blocco abbattuto, bocca uccisa, super potere, scossa, cambio livello, muro spinto).
> - Zuccherini ben distribuiti: uno per ognuna delle 8 sezioni, su tutta la larghezza dello schermo, sopra e sotto il piano. Ognuno è fuori dagli oggetti indistruttibili oppure dentro una tazza o un muro di cioccolato, da bucare a colpi di cioccolatino.
> - Si può sparare tenendo premuta una direzione.
> - **Più suspense**:
>   - *fuga finale*: quando compare il sacchetto le bocche vanno al doppio della velocità e la musica raddoppia il ritmo;
>   - *tempo in scadenza*: negli ultimi 2 segmenti la barra del tempo lampeggia in rosso, la musica accelera e si sente un battito del cuore;
>   - *bonus tempo*: a fine livello ogni segmento di tempo rimasto vale 20 punti, contati uno alla volta;
>   - *fine super potere*: nell'ultimo secondo il biscotto lampeggia più veloce e tre bip avvisano che sta finendo;
>   - *combo partita perfetta*: finché nel livello non perdi una vita ogni zuccherino vale doppio (100 punti invece di 50);
>   - lo zuccherino dorato (super potere) è giallo, lo zuccherino chiave è azzurro.
> - **Levette di difficoltà** (lette a ogni inizio livello): sinistra in A = Bocche più veloci; destra in A = il livello parte con 6 tacche di tempo invece di 8 e niente bonus tempo. In B il gioco è normale.
> - **Livello 6, le presse**: solo presse, 4 appese al soffitto e 4 al piano. Ogni pressa è uno stantuffo a T (perno sottile, testa larga) che scende fino in fondo a ritmo, sfasata dalle vicine come un'onda: se ti prende sotto perdi una vita. Il livello parte al buio.
> - **Livello segreto: la Bocca Gigante** (boss, dopo il livello 6). Una bocca enorme con i denti insegue il biscotto e gli sputa contro: lo sputo toglie una vita. Si batte con 8 colpi di cioccolatino; la barra dell'energia sul pavimento si svuota a ogni colpo. Ogni colpo la respinge nell'angolo opposto e la rende più veloce; dopo il quarto colpo sputa tre volte al secondo, dopo il quinto lampeggia. Ogni colpo vale 50 punti, la vittoria 500 in più, poi compare il sacchetto. Non si sceglie con Select, ma con una **combinazione segreta**: nel titolo tieni la leva in su e il pulsante premuti (si accende un 7° segnalino) e premi Reset.
> - Altre correzioni: un colpo alla bocca vale +10 una volta sola; la luce si spegne a 32 secondi ma si può riaccendere subito, e ogni nuovo livello parte con la luce accesa (tranne il 5).
> - La ROM viene provata in automatico nell'emulatore Stella: [`snack_and_roll/tests`](snack_and_roll/tests/README.md).

---

## 🕹 INTRODUZIONE  
Benvenuto nella cucina più pericolosa del mondo!  
In *Snack 'n' Roll™*, tu sei **BISCO**, un piccolo biscotto tondo e veloce che deve attraversare una serie di livelli casalinghi pieni di ostacoli, nemici e pericoli... per poter raggiungere il Dispenser Supremo di Biscotti!  
Ma fai attenzione! Le formiche assassine, le gocce di cioccolato infuocate e i lavandini traboccanti faranno di tutto per fermarti.  
Hai il coraggio… e il croccante giusto?

---

## 🕹️ Snack 'n Roll – Regolamento Ufficiale

### 🎯 Obiettivo del gioco  
Guida il Biscotto attraverso 20 livelli pieni di ostacoli, nemici e imprevisti.  
Raccogli 8 cioccolatini per sbloccare il sacchetto finale, evita la Bocca e gestisci tempo, munizioni e luci per sopravvivere e progredire.

### Struttura e ambientazione  
Ogni livello è suddiviso in 4 aree principali del playfield dinamico, suddivise in parte alta e parte bassa.

**🌍 Ambientazioni ricorrenti:**  
- Tazze  
- Coltelli  
- Cioccolato (muri animati)  
- Gocce (animate)  
- Lampade  
- Tavoli  
- Piano di lavoro

### 👾 Personaggi e oggetti  
- **Biscotto** : Il tuo personaggio, 8x4 pixel.  
- **Bocca** : Nemico che si muove casualmente.  
- **Cioccolatini** : Posizionati nel playfield, forniscono munizioni.  
- **Sacchetto finale** : Appare solo dopo aver raccolto 8 cioccolatini e colpito la Bocca.

---

## ⚙️ Meccaniche di gioco

### 🚶‍♂️ Movimento e rallentamento  
Se il Biscotto tocca il playfield (gli elementi decorativi o ostacoli) entra in slow motion per alcuni secondi.  
Durante lo slow motion:  
- Il Biscotto cambia colore.  
- Il lancio dei cioccolatini è disabilitato.

### 🔫 Spari e munizioni  
- Il Biscotto può lanciare cioccolatini se ha scorte e non è in slow motion.  
- Colpendo oggetti nel playfield, si possono recuperare cioccolatini/munizioni.  
- Colpendo la Bocca:  
  - Guadagni 10 punti.  
  - Disattivi temporaneamente la Bocca.

### ⏱️ Gestione del tempo  
- Il livello deve essere completato prima che la barra del tempo (sinistra) si esaurisca.  
- Ogni 16 secondi, si riduce una tacca di tempo.  
- Se la barra del tempo termina, perdi una vita (barra destra).  
- Quando il tempo è agli sgoccioli (ultimi 2 segmenti), la barra lampeggia in rosso, la musica accelera e si sente un battito del cuore.  
- A fine livello ogni segmento di tempo rimasto vale 20 punti di bonus.

### 💡 Gestione della luce  
Dopo 32 secondi, la luce si spegne automaticamente:  
- Il playfield lampeggia.  
- La Bocca diventa invisibile.  

Per riaccendere la luce: spara un cioccolatino sul piano centrale.

---

## 🧱 Progressione e difficoltà  
La Bocca aumenta di dimensioni dopo:  
- Livello 6  
- Livello 12  

La sua velocità aumenta con i livelli (es. aggiornamento iniziale ogni 8 secondi).

---

## ❤️ Vite e game over  
- Se il Biscotto viene colpito dalla Bocca → perdi una vita.  
- Se finisce il tempo → perdi una vita.  
- Finite le vite? → Game Over.

---

## 🧮 Sistema di punteggio  
Il punteggio al centro dello schermo è composto da due parti:  
- Parte sinistra: punteggio totale.  
- Ultime 2 cifre a destra: numero massimo di cioccolatini/munizioni disponibili per essere sparati.

Nella versione Atari aggiornata:
- zuccherino: 50 punti, **100** se nel livello non hai ancora perso una vita (combo "partita perfetta");
- bocca colpita o schiacciata da un muro: 10 punti;
- bonus tempo a fine livello: 20 punti per ogni segmento rimasto della barra del tempo.
- Bocca Gigante: 50 punti per ogni colpo, 500 in più quando è sconfitta.

---

## 🚪 Cambio di livello  
Per completare un livello devi:  
- Raccogliere 8 cioccolatini nel playfield.  
- Colpire la Bocca con un cioccolatino.  
- Raggiungere il sacchetto finale.

---

*Buon divertimento con Snack 'n' Roll™!*  
---

