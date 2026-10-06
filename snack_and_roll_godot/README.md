# Snack 'n' Roll – versione Godot 4

Porting di `snack_and_roll/Snack and Roll.bas` (batari Basic, Atari 2600) in **Godot 4.3**.
È un platform 2D a scorrimento orizzontale: i 5 livelli del BAS sono messi uno dopo l'altro
in un unico mondo che si attraversa da sinistra a destra.
Non usa asset esterni: grafica, luci, particelle e suono (emulazione del chip TIA) sono tutti
generati dal codice.

## Come avviarlo

1. Installa Godot **4.3** o successivo (va bene la versione standard, non serve .NET).
2. *Importa* la cartella `snack_and_roll_godot/` (file `project.godot`) e premi **F5**.

Test automatico (non serve la finestra):

```
godot --headless --path snack_and_roll_godot -s tests/smoke_test.gd
```

## Comandi

| Azione | Tastiera | Joypad | Atari 2600 |
|---|---|---|---|
| Muovi | ← → / A D | levetta / croce | joystick |
| Salto (premi di nuovo in aria per il *roll*, cioè il doppio salto) | Spazio / Z / K | A | – |
| Lancia un cioccolatino | X / J / Ctrl | X / B | fire |
| Mira in alto / in basso (in aria) | ↑ / ↓ | levetta | joystick |
| Inizia la partita | Invio / F2 | Start | **Reset** (F2 in Stella) |
| Livello iniziale (1-5) | Tab / F1 | Back | **Select** (F1 in Stella) |
| Pausa, audio | P / Esc, M | – | – |

## Regole (le stesse del BAS)

- Raccogli gli **8 zuccherini** del livello (+50 ciascuno).
  - Lo zuccherino **dorato** (indice 0) congela le bocche e ti rende invulnerabile per 2 secondi (`_hitCooldown = 120`).
  - Lo zuccherino **chiave** (indice 1) dà `_hasKey`, che serve dal livello 4.
- Colpisci **almeno una Bocca** con un cioccolatino (+10). Senza questo il sacchetto non appare.
- Quando appare il **sacchetto**, toccalo: il cancello a destra si apre e passi al livello successivo.
- **Tempo**: ogni 16 secondi perdi una tacca; quando la barra è vuota perdi una vita.
- **Vite**: 4 (`pfscore2 = %10101010`, divisa per 4 a ogni colpo). Le Bocche costano una vita.
- **Luce**: dopo 32 secondi si spegne e nel buio le Bocche si vedono solo vicino al biscotto.
  Per riaccenderla spara sul *piano di lavoro* (il ripiano di marmo) o tocca/colpisci una lampada. Il livello 5 inizia al buio.
- **Cioccolato fuso** (muri e gocce): ti appiccica e ti rallenta (slow motion) fino al prossimo multiplo di 8 secondi. In slow motion non puoi sparare.
- Con un cioccolatino distruggi la **riga più alta** di tazze, tavoli e muri di cioccolato (+1).
- Dal livello 4 le Bocche sono **2 e larghe il doppio**. La seconda (e dal livello 5 tutte) attraversa i muri.
- Livello 5: il **muro spingibile** (`_pushCol`). Se lo colpisci con un cioccolatino torna alla posizione iniziale.

## Novità della versione Godot

| Novità | Dove |
|---|---|
| Scorrimento orizzontale continuo attraverso tutti i livelli, cancelli animati | `level_builder.gd`, `hazards.gd` (Gate) |
| Salto con *roll* (doppio salto), coyote time, schiacciamento ed elasticità, rotolamento | `player.gd` |
| Pozze di **cioccolata bollente** (cadere costa una vita) | `EXT_PITS`, Pit |
| **Coltelli a scatto** dal pavimento (riprendono la colonna "COLTELLI" rimasta vuota nel BAS) | `EXT_KNIVES`, Knife |
| **Cialde fragili** che si sbriciolano (livelli 3-5) | `EXT_CRUMBLE`, `block.gd` |
| **Vapore** delle tazze che ti spara in alto | Steam |
| Gocce di cioccolato che cadono davvero, lampade con luce dinamica, buio con torcia sul biscotto | DropSource, Lamp, `main.gd` |
| Sfondo a parallasse con 5 temi (cucina, dispensa, pasticceria, fabbrica, mezzanotte) | `background.gd` |
| Particelle, scritte "+50", tremolio della camera, record salvato | `fx.gd`, `main.gd` |

Le tabelle `EXT_*` in `snack_data.gd` sono le uniche cose senza equivalente nel BAS:
svuotale per avere solo il gioco originale.

## Struttura

```
project.godot            impostazioni (480x270, renderer Compatibility)
scenes/main.tscn         scena principale (un solo nodo; il resto lo crea il codice)
scripts/snack_data.gd    TABELLE DEL BAS (objects, sugar, jingle, melody, ...) + EXT_
scripts/main.gd          __main_loop: timer, luce, punteggi, livelli, bocche, sacchetto
scripts/level_builder.gd playfield dinamico: da "objects" ai blocchi del mondo
scripts/block.gd         pixel/oggetti del playfield (distruttibili, appiccicosi, fragili)
scripts/player.gd        il biscotto (player0)
scripts/mouth.gd         le bocche (player1)
scripts/projectile.gd    il cioccolatino lanciato (missile0)
scripts/sugar.gd         gli zuccherini (missile1)
scripts/bag.gd           il sacchetto finale (ball)
scripts/hazards.gd       gocce, lampade, cancello, muro spingibile, vapore, coltelli, pozze
scripts/hud.gd           pfscore1/pfscore2/score + titolo e modalità attract
scripts/synth.gd         audio TIA emulato (autoload "Synth")
scripts/background.gd    sfondo a parallasse
tests/                   test automatico e cattura screenshot
```

## Tabella di porting BAS → Godot

Ogni variabile del BAS ha lo stesso nome (senza `_`) in `main.gd`.
Così una modifica fatta da una parte si può riportare dall'altra.

| BAS | Godot | Note |
|---|---|---|
| `_level` (b) | `main.level` | 1..5 |
| `_frame_counter` (c), `frame_limit` | `frame_counter`, `D.FRAME_LIMIT` | 54 a 50 Hz → 59 a 60 Hz |
| `_seconds_counter` (d) | `seconds_counter` | fermo mentre si passa il cancello |
| `_choco_count` (t) | `choco_count` | sul titolo = livello scelto − 1, come nel BAS |
| `_choco_bits` (e), `bittable` | `choco_bits`, `D.BITTABLE` | |
| `_speed` (g) | `speed`, `D.mouth_speed()` | velocità della bocca in px/s |
| `_b0_enableStart` | `state` | `"title"`, `"playing"`, `"gameover"`, `"victory"` |
| `_b2_loadPlayfield` | `_build_world()` | il mondo si costruisce una volta sola |
| `_b4_enableLight` | `enable_light` | `CanvasModulate` + `PointLight2D` |
| `_b5_enablePalyer1` | `enable_player1` | `true` finché nessuna bocca è stata colpita |
| `_b6_enableSlowMotion` | `slow_motion` | |
| `_b7_gameMissile0Moving` | `missile_moving` | |
| `_BitOp_P0_M0_Dir` | `player.facing` + mira su/giù | |
| `_hitCooldown` (v) | `hit_cooldown` | 90 se colpito, 120 con lo zuccherino dorato |
| `_hasKey` (z) | `has_key` | |
| `_pushCol` (s) | `PushBlock` (`D.PUSH_COL_*`) | |
| `_mouthIndex`, `_mouth0x/y`, `_mouth1x/y` | un nodo `mouth.gd` per bocca | niente multiplexing: ogni bocca è un nodo |
| `_sugarIndex`, `_prevSugarBit` | un nodo `sugar.gd` per zuccherino | |
| `_music_index` (m), `jingle`, `melody` | `music_index`, `Synth.note()` | |
| `_attractTimer`, `_attractDir` | `attract_timer`, `attract_dir` | |
| `pfscore1` / `pfscore2` / `score` / `scorecolor` | stessi nomi | stessi valori a bit |
| `objects`, `sugar`, `mouthcolors` | `D.OBJECTS`, `D.SUGAR`, `D.MOUTH_COLORS` | valori identici |
| `__decrease_health_bar` | `decrease_health_bar()` | |
| `__decrease_timer_bar` | `_decrease_timer_bar()` | |
| `__destroy_mouth`, `__reset_mouth_pos` | `destroy_mouth()`, `mouth_reset_pos()` | |
| `__change_level`, `__skip_to_change` | `change_level()`, `_skip_to_change()` | |
| `__handle_level_select` | `D.speed_for_level()` | |
| macro `cup_knife`, `chocolate`, `choco_drops`, `lamp`, `table`, `divisor` | `_cup`, `_chocolate`, `_drops`, `_lamp`, `_table`, ciclo PIANO in `level_builder.gd` | |

### Dal playfield 32×11 al mondo a scorrimento

Ogni livello diventa un tratto di 128×17 tile da 16 px:

```
riga 0       soffitto
righe 1-8    sezioni ALTE  b0 b1 b2 b3 (32 tile ciascuna)
riga 9       PIANO DI LAVORO (colonna 6 di objects, 7 segmenti)
righe 10-14  sezioni BASSE b4 b5 b6 b7
righe 15-16  pavimento (con le pozze EXT_PITS)
colonna 127  cancello verso il livello successivo
```

- Zuccherini: valore `v` di `data sugar` → colonna `v&7`, riga `v>>3` (righe 0-3 sopra il piano, 5-7 sotto).
- Sacchetto: `ballx` = 18 → inizio del tratto, 136 → fine del tratto.

### Differenze volute rispetto al BAS

- Lo slow motion scatta toccando il **cioccolato** (muri e gocce), non ogni oggetto: in un platform il contatto con il pavimento è continuo.
- Con `_speed = 0` (livello 5) nel BAS la bocca quasi non si muove (effetto di `frame & 255`). Qui diventa la velocità più alta.
- La luce si spegne una sola volta allo scoccare dei 32 secondi, invece di restare forzata spenta per tutto quel secondo.
- Se una bocca resta troppo indietro rientra dal bordo dello schermo.
