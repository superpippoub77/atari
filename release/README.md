# Snack 'n' Roll – Download

Tutte le versioni del gioco, pronte da usare.

| Piattaforma | File | Come si usa |
|---|---|---|
| **Atari 2600** (originale) | [`atari2600/SnackAndRoll.bin`](atari2600/SnackAndRoll.bin) | ROM da 8K (PAL). Aprila con l'emulatore [Stella](https://stella-emu.github.io/) o caricala su una cartuccia flash (Harmony, PlusCart, UnoCart). F2 = Reset (gioca), F1 = Select (livello). |
| **Atari 2600** (sorgente) | [`atari2600/Snack and Roll.bas`](atari2600/Snack%20and%20Roll.bas) | Sorgente batari Basic da cui è compilata la ROM. |
| **Windows** 64 bit | [`windows/SnackAndRoll-windows-x86_64.zip`](windows/SnackAndRoll-windows-x86_64.zip) | Estrai lo zip e avvia `SnackAndRoll.exe`. Al primo avvio Windows SmartScreen può avvisare che l'app non è firmata: *Ulteriori informazioni → Esegui comunque*. |
| **Linux** 64 bit | [`linux/SnackAndRoll-linux-x86_64.zip`](linux/SnackAndRoll-linux-x86_64.zip) | Estrai lo zip e avvia `./SnackAndRoll.x86_64` (se serve: `chmod +x SnackAndRoll.x86_64`). |
| **Android** (telefoni e tablet) | [`android/SnackAndRoll-android.apk`](android/SnackAndRoll-android.apk) | Copia l'APK sul telefono e aprilo. Consenti "installa app sconosciute" quando richiesto. Android 7.0 o superiore, ARM 32/64 bit. Comandi touch sullo schermo. |
| **Browser** (anche iPhone/iPad) | [`web/`](web/) | Versione HTML5: pubblica la cartella su un qualsiasi hosting statico (GitHub Pages, itch.io…) e apri `index.html`. Non funziona aprendo il file direttamente dal disco. |

## Note

- Le versioni Windows, Linux, Android e Web sono il **porting Godot 4.3**: un platform a scorrimento orizzontale che usa la stessa logica del BAS.
  Il codice sorgente è in [`../snack_and_roll_godot/`](../snack_and_roll_godot/README.md).
- La ROM Atari è stata ricompilata dal sorgente più recente con batari Basic 1.9 e dasm.
- L'APK Android è firmato con una chiave di sviluppo (installazione manuale, non Play Store).
  Per aggiornarlo con una build firmata con una chiave diversa, disinstalla prima la versione precedente.
- iOS: un'app nativa richiede macOS e Xcode. Su iPhone e iPad si può giocare con la versione **Browser**.

## Verifiche fatte

| Versione | Come è stata provata |
|---|---|
| Atari 2600 | Emulatore Stella: partita completa dal livello 1 alla vittoria giocata in automatico con i tasti. Sono 315 controlli su zuccherini, bocche, sacchetto, appoggi degli oggetti, luce, tempo, vite e muro spingibile ([`snack_and_roll/tests`](../snack_and_roll/tests/README.md)) |
| Windows | Wine 9 su Linux: avvio, titolo, partita |
| Linux | Avvio diretto del binario esportato |
| Browser | Chromium: caricamento, titolo, partita, nessun errore in console |
| Android | Firma APK verificata con `apksigner` (v1/v2/v3); da provare su un dispositivo |

## Come ricompilare

```bash
# Atari 2600 (batari Basic 1.9)
2600basic.sh "Snack and Roll.bas"

# Godot (dalla cartella snack_and_roll_godot, template di esportazione 4.3 installati)
godot --headless --path . --export-release "Windows"
godot --headless --path . --export-release "Linux"
godot --headless --path . --export-release "Web"
godot --headless --path . --export-release "Android"   # richiede Android SDK e keystore
```
