# 🐟 Boris Bar (GNOME Shell Extension)

> ⚠️ **FAN PROJECT NON COMMERCIALE — NON-COMMERCIAL FAN PROJECT**  
> Questo è un progetto amatoriale gratuito, open source, senza scopo di lucro né valore commerciale, creato da un fan della serie *Boris* per uso personale e di altri fan. Non è affiliato, sponsorizzato, approvato o in alcun modo connesso con RAI, Wildside, Sky, Mediaset, Disney+, o con gli autori, registi, interpreti o detentori dei diritti della serie. Tutti i marchi, titoli, personaggi, dialoghi e opere derivate sono proprietà dei rispettivi titolari.  
> Questo repository e questa estensione **non distribuiscono alcun file audio**: forniscono esclusivamente il riproduttore e l'integrazione GNOME Shell. Ottenere eventuali clip audio e verificarne la legittima disponibilità per l'uso locale è **responsabilità esclusiva dell'utente**.  
> **Nessun ricavo, donazione, pubblicità o monetizzazione è associato a questo progetto.**  
> Se sei il titolare dei diritti e desideri la rimozione dei contenuti, apri una [issue](https://github.com/ercoppa/boris-bar-gnome-extension/issues): i file verranno rimossi tempestivamente.

---

Estensione per GNOME Shell 45-49 ispirata alla serie TV italiana *Boris*. Fornisce un riproduttore di clip audio con shortcut globali direttamente dal pannello superiore, ma **non include né redistribuisce file audio**.

Il concept originale di *Boris Bar* nasce dall'[app per macOS](https://github.com/andrearicciotti1/boris-bar) realizzata da **Andrea Ricciotti**, qui citata come ispirazione originaria del progetto.

Zero dipendenze esterne, basato interamente su GJS, GStreamer (nativo in GNOME) e GTK4.

---

## ✨ Features

- 🎣 Icona pesce rosso nel pannello GNOME
- 🎧 9 clip audio con shortcut globali predefiniti (`<Super><Alt>1` … `<Super><Alt>9`), personalizzabili tramite `dconf`
- ➕ Carica i tuoi suoni personalizzati nella cartella `~/.local/share/boris-bar/custom/`
- ⏱ Durata max 30s per clip, toggle start/stop premendo di nuovo lo shortcut o cliccando dal menu

---

## 📦 Installazione

### Installazione Manuale

1. Clona questo repository all'interno della cartella delle estensioni di GNOME:
   ```bash
   git clone https://github.com/ercoppa/boris-bar-gnome-extension.git ~/.local/share/gnome-shell/extensions/boris-bar@ercoppa.github.com
   ```
2. Compila lo schema dconf per gli shortcut globali:
   ```bash
   glib-compile-schemas ~/.local/share/gnome-shell/extensions/boris-bar@ercoppa.github.com/schemas/
   ```
3. Riavvia GNOME Shell:
   - Su X11: `Alt+F2`, digita `r`, e premi Invio.
   - Su Wayland: disconnettiti e riconnettiti.
4. Abilita l'estensione tramite l'app **Estensioni** di GNOME o da terminale:
   ```bash
   gnome-extensions enable boris-bar@ercoppa.github.com
   ```
5. Importa localmente i clip audio dall'ultima release macOS originale, senza pubblicarli in questo repository:
   ```bash
   cd ~/.local/share/gnome-shell/extensions/boris-bar@ercoppa.github.com
   chmod +x tools/import-audio-from-dmg.sh
   ./tools/import-audio-from-dmg.sh
   ```

Nota: l'estensione installata da questo repository contiene solo codice e asset grafici. Qualsiasi clip audio va reperito separatamente dall'utente e salvato in locale sotto la propria responsabilità.

### Import audio dalla release macOS originale

Per evitare di redistribuire i clip audio come artifact di questo repository, l'estensione puo' caricare i clip built-in dalla directory locale utente:
`~/.local/share/boris-bar/builtin/`

Lo script incluso scarica il DMG originale da:
`https://github.com/andrearicciotti1/boris-bar/releases/download/v1.0/BorisBar-1.0.dmg`

ed estrae i file audio in quella cartella locale. Lo script e l'estensione fungono solo da mezzo tecnico di import/riproduzione: la disponibilità dei file audio, i diritti d'uso e la conformità legale del download restano in capo all'utente. Requisiti minimi:

- `curl`
- uno tra `7z`, `7zz`, `bsdtar`, `hdiutil`

Esecuzione manuale:

```bash
cd ~/.local/share/gnome-shell/extensions/boris-bar@ercoppa.github.com
chmod +x tools/import-audio-from-dmg.sh
./tools/import-audio-from-dmg.sh
```

Se vuoi usare un URL diverso, puoi passarlo come primo argomento:

```bash
./tools/import-audio-from-dmg.sh "https://example.com/BorisBar.dmg"
```

---

## 🎵 Aggiungere suoni personalizzati

I tuoi file audio custom (es. `mp3`, `wav`, `ogg`) vanno inseriti nella seguente cartella:
`~/.local/share/boris-bar/custom/`

Dal menu dell'estensione puoi cliccare su **Apri cartella suoni** per aprirla rapidamente.  
Nome file = label nel menu (senza estensione).

---

## ⌨️ Shortcut globali predefiniti

| Shortcut           | Clip |
|--------------------|------|
| `<Super><Alt>1`    | Fai uno sforzo |
| `<Super><Alt>2`    | Tutti basiti |
| `<Super><Alt>3`    | A cazzo di cane |
| `<Super><Alt>4`    | F4 |
| `<Super><Alt>5`    | Fiano Romano |
| `<Super><Alt>6`    | Però sei molto italiano |
| `<Super><Alt>7`    | Thank you for being so not italian |
| `<Super><Alt>8`    | Io la mollo questa serie |
| `<Super><Alt>9`    | Vuoi una pompa |

Funzionano ovunque, anche senza aprire il menu. Ripremere lo stesso shortcut ferma la riproduzione.
Puoi modificare questi shortcut tramite `dconf-editor` o da riga di comando navigando in:
`/org/gnome/shell/extensions/boris-bar/`

---

## 🛠 Stack tecnico

- **GJS** (GNOME JavaScript)
- **GStreamer (playbin)** per la riproduzione asincrona di audio senza bloccare il thread della Shell
- **dconf / gschema** per la gestione dinamica degli shortcut globali (`Main.wm.addKeybinding`)

---

## 📜 Licenza e disclaimer

### Codice sorgente
Licenza [MIT](LICENSE) — libero uso, modifica, redistribuzione per il **codice**.

### Contenuti audio (estratti della serie Boris)
- **Questo progetto non redistribuisce clip audio.** Il repository pubblica solo il codice dell'estensione e gli asset non audio; eventuali file sonori devono essere ottenuti e conservati localmente dagli utenti sotto la loro esclusiva responsabilità.
- **Non sono mia proprietà.** Tutti i diritti sui dialoghi, personaggi, opera originale appartengono a **RAI**, **Wildside**, **Sky**, **Mediaset**, **Disney+** e agli autori/interpreti della serie.
- **Provenienza:** i clip audio di default sono stati **scaricati da YouTube**, estratti da video di terzi pubblicamente accessibili. L'autore di questa estensione GNOME non è la fonte originale.
- **Uso:** esclusivamente illustrativo, satirico, di omaggio (*tribute*), educativo e di commento critico alla serie.
- **Fair use / eccezioni copyright:** il progetto si appoggia ai principi di *fair use* (USA) e alle eccezioni previste dalla direttiva UE 2019/790 art. 17(7) e dall'art. 70 L. 633/1941.

### Nessuno scopo di lucro
- ❌ Nessuna vendita, nessuna donazione, nessun annuncio pubblicitario, nessuna promozione a pagamento
- ❌ Nessun paywall, nessun abbonamento, nessuna in-app purchase
- ❌ Nessuna telemetria, nessuna analitica, nessun tracciamento utenti
- ✅ Gratis, open source, auto-contenuto, offline

### Nessuna affiliazione
Boris Bar **non è** un prodotto ufficiale. **Non è** affiliato, sponsorizzato, approvato o in alcun modo connesso con RAI, Wildside, Sky, Mediaset, Disney+, gli autori o gli interpreti della serie *Boris*.

### Takedown policy / contatto DMCA
Se sei un detentore di diritti e vuoi la rimozione dei contenuti:

🐛 Apri una [issue](https://github.com/ercoppa/boris-bar-gnome-extension/issues) su GitHub

Per richieste valide, i file saranno rimossi **entro 24 ore dalla ricezione**.

---

> *"Basito."*
