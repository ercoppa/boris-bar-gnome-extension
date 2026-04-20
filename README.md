# 🐟 Boris Bar

Menu bar app macOS ispirata alla serie TV italiana *Boris*. Clip audio iconici della serie a portata di shortcut globale, dalla menu bar del Mac.

Ultra-leggera (~4 MB RAM idle), zero dipendenze, Swift nativo + Cocoa + AVFoundation.

![screenshot](docs/screenshot.png)

---

## ✨ Features

- 🎣 Icona pesce rosso nella menu bar (invisibile nel Dock)
- 🎧 9 clip audio con shortcut globali `⌥⌘1` … `⌥⌘9`
- ➕ Carica i tuoi suoni personalizzati via file picker
- ⏱ Durata max 30s per clip, toggle start/stop premendo di nuovo lo shortcut
- 🚀 Avvia al login (opzionale, togglable dal menu)
- 🪶 Binario 100 KB, nessun Electron, nessun Python

---

## 📦 Installazione

### Opzione A — DMG (consigliata)

1. Scarica `BorisBar-1.0.dmg` dall'ultima [Release](../../releases/latest)
2. Aprilo e trascina `BorisBar.app` nella cartella `Applications`
3. **Primo avvio — rimuovere la quarantena:** l'app non è firmata Apple Developer ID, quindi macOS la marca come "danneggiata". Apri Terminale e lancia una volta:
   ```bash
   xattr -cr /Applications/BorisBar.app
   ```
   Poi apri l'app normalmente col doppio click.  
   (Alternativa: tasto destro → **Apri** → **Apri** — funziona solo su versioni vecchie di macOS, su Sequoia / Tahoe serve il comando sopra.)
4. Clicca il pesce nella menu bar → scegli un clip.

### Opzione B — Build dai sorgenti

```bash
git clone https://github.com/andrearicciotti1/boris-bar.git
cd boris-bar
# Metti i tuoi file audio (mp3/wav/m4a) in assets/clips/
./build.sh
open BorisBar.app
```

Richiede macOS 13+ e Command Line Tools (`xcode-select --install`).

---

## 🎵 Aggiungere suoni personalizzati

Dal menu dell'app:

- **"Aggiungi suono personalizzato…"** → file picker → il suono viene copiato in  
  `~/Library/Application Support/BorisBar/custom/` e compare nel menu
- **"Apri cartella suoni"** → per rinominare/cancellare manualmente

Formati supportati: `mp3`, `mp4`, `m4a`, `wav`, `aiff`, `caf`.  
Nome file = label nel menu.

---

## ⌨️ Shortcut globali predefiniti

| Shortcut | Clip |
|----------|------|
| `⌥⌘1`    | F4 |
| `⌥⌘2`    | Tutti basiti |
| `⌥⌘3`    | A cazzo di cane |
| `⌥⌘4`    | Fai uno sforzo |
| `⌥⌘5`    | Fiano Romano |
| `⌥⌘6`    | Però sei molto italiano |
| `⌥⌘7`    | Thank you for being so not italian |
| `⌥⌘8`    | Io la mollo questa serie |
| `⌥⌘9`    | Vuoi una pompa |

Funzionano ovunque, anche senza aprire il menu. Ripremere lo stesso shortcut ferma la riproduzione.

---

## 🛠 Stack tecnico

- **Swift** (single-file `boris_bar.swift`, ~200 righe)
- **Cocoa** — NSStatusItem, NSMenu
- **AVFoundation** — AVAudioPlayer
- **ServiceManagement** — SMAppService per login item (macOS 13+)
- **Carbon.HIToolbox** — RegisterEventHotKey per shortcut globali (zero permessi accessibility)

---

## 📜 Licenza

[MIT](LICENSE) per il codice.

I clip audio della serie *Boris* sono di proprietà di RAI / Wildside / Sky e **non** sono inclusi in questo repo. Devi fornire i tuoi file. L'app è pensata per uso personale, non commerciale.

---

## 🤘 Autore

[PunxCode](https://punxcode.com) — Andrea Ricciotti

---

> *"Basito."*
