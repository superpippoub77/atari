# Circular Defense – Atari 2600

Al centro dello schermo un cannone spara contro 6 città disposte in cerchio. Il tuo difensore gira attorno al cannone e para i colpi. Si muove solo quando lo muovi tu: col **paddle** o col joystick.

Ispirato al prototipo HTML *Circular Defense*, riscritto in batari Basic per Atari 2600: PAL, cartuccia 8K con bankswitching F8, senza RAM aggiuntiva.

![Schermate](screenshots/tavola.png)

## Comandi

| Comando | Effetto |
| --- | --- |
| **Paddle** (predefinito) | Il difensore va all'angolo della manopola: tutta la corsa del paddle corrisponde a un giro completo. Pulsante: inizia la partita. |
| **Joystick** | Destra = senso orario, sinistra = senso antiorario; col fuoco premuto gira al doppio. Fuoco: inizia la partita. |
| Game Select (fuori partita) | Cambia controller. La barra in basso a destra è accesa quando è scelto il paddle. |
| Game Reset | Inizia la partita. |
| Levetta di difficoltà sinistra in A | Colpi più veloci. |
| Levetta di difficoltà destra in A | Il cannone spara più spesso. |

Il paddle va nella porta sinistra (il primo paddle della coppia).

## Regole

- **Le città.** Ognuna ha una torre, una fila di palazzi e la base: 8 pezzetti. Ogni colpo non parato toglie un pezzetto alla città colpita, sempre dall'alto. Quando una città non ha più pezzetti è distrutta, e i colpi diretti lì cadono sulla città più vicina ancora in piedi.
- **I livelli.** Sono 8. In ognuno devi parare un certo numero di colpi. La barra gialla in basso a sinistra conta i livelli.
- **Fine livello.** Ricevi 5 punti per ogni pezzetto di città rimasto, contati uno alla volta. Le città danneggiate non si ricostruiscono.
- **Fine partita.** Dopo l'8° livello compare **VITTORIA** (+500 punti, con la fanfara). Se cadono tutte le città compare **GAME OVER**. Col pulsante si torna al titolo.

| Livello | Colpi da parare | Colpi insieme | Velocità | Sorprese |
| --- | --- | --- | --- | --- |
| 1 | 8 | 1 | lenta | – |
| 2 | 10 | 2 | | – |
| 3 | 12 | 2 | | – |
| 4 | 12 | 2 | | colpi deviati |
| 5 | 14 | 2 | | – |
| 6 | 14 | 2 | | buio |
| 7 | 16 | 2 | | colpi deviati |
| 8 | 20 | 2 | massima | colpi deviati + buio |

- **Colpi deviati.** A metà strada, proprio dove passa il difensore, metà dei colpi cambia bersaglio e va sulla città vicina.
- **Buio.** I colpi si vedono solo un fotogramma su quattro.

| Azione | Punti |
| --- | --- |
| Colpo parato | 10 |
| Pezzetto di città rimasto a fine livello | 5 |
| Vittoria | 500 |

## File

| File | Contenuto |
| --- | --- |
| `Circular Defense.bas` | Sorgente batari Basic |
| `bin/Circular Defense.bas.bin` | ROM da 8K (PAL), da aprire con Stella o da caricare su una cartuccia |
| `tools/gen_tables.py` | Genera città e pezzetti, traiettorie dei colpi (anche deviate), orbita del difensore, tabella del paddle |
| `tools/gen_sprites.py` | Genera la torretta del cannone (8 direzioni) e il difensore |
| `tools/gen_text.py` | Genera le scritte del playfield (titolo, GAME OVER, VITTORIA) con un font 3×5 |
| `tools/update_bas.py` | Rigenera nel sorgente le parti prodotte dai tre script |
| `tests/test_game.py` | Test nell'emulatore Stella (31 controlli, con joystick e paddle) |

## Come funziona

- **Paddle.** Il kernel di batari Basic li legge con le opzioni `no_blank_lines readpaddle`. La lettura usa la memoria del missile 0, quindi il secondo colpo è disegnato con la *ball*.
- **Colpi.** La posizione è a virgola fissa 8.8 e ogni colpo fa 64 passi dal centro alla città. Un colpo deviato, al passo 32, prende una seconda velocità che lo porta sulla città vicina negli ultimi 32 passi.
- **Parata.** Il programma confronta la posizione del colpo con quella del difensore invece di usare le collisioni del chip grafico (TIA). Così funziona anche al buio, quando il colpo non viene disegnato.
- **Città.** I pezzetti sono pixel del playfield. Per sapere cosa resta in piedi il gioco legge il playfield (`pfread`), senza usare altra RAM.

## Test

```bash
cd circular_defense/tests
xvfb-run -a -s "-screen 0 800x600x24" python3 test_game.py . "../bin/Circular Defense.bas.bin" /tmp/screenshot
```

In Stella il joystick va forzato con `-lc JOYSTICK` e i paddle con `-lc PADDLES`. Il test lo fa da solo.
