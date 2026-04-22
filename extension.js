import St from 'gi://St';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import Clutter from 'gi://Clutter';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';
import Gst from 'gi://Gst';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';

const BUILTIN_CLIPS = [
    { label: "Fai uno sforzo", base: "fai uno sforzo" },
    { label: "Tutti basiti", base: "Tutti basiti" },
    { label: "A cazzo di cane", base: "a cazzo di cane" },
    { label: "F4", base: "F4" },
    { label: "Fiano Romano", base: "Fiano Romano" },
    { label: "Però sei molto italiano", base: "Però sei molto italiano" },
    { label: "Thank you for being so not italian", base: "Thank you for being so not italian" },
    { label: "Io la mollo questa serie", base: "Io la mollo questa serie" },
    { label: "Vuoi una pompa", base: "Vuoi una pompa" }
];

const AUDIO_EXTS = ["mp3", "mp4", "m4a", "wav", "aiff", "aif", "caf", "ogg"];
const BUILTIN_CLIPS_DIR = 'builtin';

function normalizeClipName(name) {
    return name.normalize('NFC').toLocaleLowerCase();
}

class AudioPlayer {
    constructor() {
        Gst.init(null);
        this.pipeline = Gst.ElementFactory.make("playbin", "playbin");
        this.bus = this.pipeline.get_bus();
        this.bus.add_signal_watch();
        this.busId = this.bus.connect("message::eos", () => {
            this.stop();
        });
        this.currentUrl = null;
        this.timeoutId = null;
    }

    play(url) {
        if (this.currentUrl === url) {
            // toggle stop
            this.stop();
            return;
        }
        this.stop();
        this.currentUrl = url;
        this.pipeline.set_property("uri", url);
        this.pipeline.set_state(Gst.State.PLAYING);
        
        // Stop after 30s as in the original app
        this.timeoutId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 30000, () => {
            this.stop();
            return GLib.SOURCE_REMOVE;
        });
    }

    stop() {
        if (this.pipeline) {
            this.pipeline.set_state(Gst.State.NULL);
        }
        this.currentUrl = null;
        if (this.timeoutId) {
            GLib.source_remove(this.timeoutId);
            this.timeoutId = null;
        }
    }

    destroy() {
        this.stop();
        if (this.busId && this.bus) {
            this.bus.disconnect(this.busId);
            this.bus.remove_signal_watch();
        }
        this.pipeline = null;
    }
}

const BorisBarIndicator = GObject.registerClass(
class BorisBarIndicator extends PanelMenu.Button {
    _init(extension) {
        super._init(0.0, 'Boris Bar');
        this._extension = extension;
        this._audioPlayer = new AudioPlayer();

        // Add fish icon
        let iconPath = extension.dir.get_child('assets').get_child('fish.svg').get_path();
        if (GLib.file_test(iconPath, GLib.FileTest.EXISTS)) {
            let gicon = Gio.icon_new_for_string(iconPath);
            let icon = new St.Icon({
                gicon: gicon,
                style_class: 'system-status-icon',
            });
            this.add_child(icon);
        } else {
            // Fallback icon if not found
            let icon = new St.Icon({
                icon_name: 'audio-volume-high-symbolic',
                style_class: 'system-status-icon',
            });
            this.add_child(icon);
        }

        this._buildMenu();
    }

    _buildMenu() {
        this.menu.removeAll();

        // Built-ins
        BUILTIN_CLIPS.forEach((clip, i) => {
            let item = new PopupMenu.PopupMenuItem(clip.label);
            
            // Add right-aligned shortcut label
            let shortcutLabel = new St.Label({
                text: `<Super><Alt>${i + 1}`,
                x_expand: true,
                x_align: Clutter.ActorAlign.END,
                opacity: 150 // dim the shortcut text
            });
            item.add_child(shortcutLabel);

            item.connect('activate', () => this._playBuiltIn(clip.base));
            this.menu.addMenuItem(item);
        });

        // Custom sounds
        let customClips = this._loadCustomClips();
        if (customClips.length > 0) {
            this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
            let header = new PopupMenu.PopupMenuItem("Suoni personalizzati");
            header.setSensitive(false);
            this.menu.addMenuItem(header);

            customClips.forEach(file => {
                let label = file.get_basename().replace(/\.[^/.]+$/, "");
                let item = new PopupMenu.PopupMenuItem(label);
                item.connect('activate', () => this._audioPlayer.play("file://" + file.get_path()));
                this.menu.addMenuItem(item);
            });
        }

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        let addCustomItem = new PopupMenu.PopupMenuItem("Aggiungi suono personalizzato…");
        addCustomItem.connect('activate', () => this._addCustomSound());
        this.menu.addMenuItem(addCustomItem);

        let openDirItem = new PopupMenu.PopupMenuItem("Apri cartella suoni");
        openDirItem.connect('activate', () => this._openCustomDir());
        this.menu.addMenuItem(openDirItem);

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        let aboutItem = new PopupMenu.PopupMenuItem("Informazioni e disclaimer...");
        aboutItem.connect('activate', () => {
            Gio.AppInfo.launch_default_for_uri(this._extension.dir.get_child('DISCLAIMER.txt').get_uri(), null);
        });
        this.menu.addMenuItem(aboutItem);
    }

    _addCustomSound() {
        // Use zenity to pick a file safely outside the shell process
        try {
            let proc = Gio.Subprocess.new(
                ['zenity', '--file-selection', '--title=Scegli un file audio'],
                Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE
            );
            
            proc.communicate_utf8_async(null, null, (proc, res) => {
                try {
                    let [, stdout] = proc.communicate_utf8_finish(res);
                    if (proc.get_successful() && stdout) {
                        let filePath = stdout.trim();
                        if (filePath) {
                            let src = Gio.File.new_for_path(filePath);
                            let dstDir = this._getCustomDir();
                            let dst = dstDir.get_child(src.get_basename());
                            
                            src.copy(dst, Gio.FileCopyFlags.OVERWRITE, null, null);
                            
                            // Rebuild menu to show the new sound
                            this._buildMenu();
                        }
                    }
                } catch (e) {
                    console.error("Zenity file selection failed: " + e);
                }
            });
        } catch (e) {
            console.error("Failed to spawn zenity: " + e);
            Main.notify("Boris Bar", "Zenity non è installato. Impossibile aprire il file picker.");
        }
    }

    _playBuiltIn(baseName) {
        let candidateDirs = this._getBuiltInClipDirs();

        for (let clipsDir of candidateDirs) {
            if (!clipsDir.query_exists(null)) {
                continue;
            }

            for (let ext of AUDIO_EXTS) {
                let file = clipsDir.get_child(`${baseName}.${ext}`);
                if (file.query_exists(null)) {
                    this._audioPlayer.play(file.get_uri());
                    return;
                }
            }

            try {
                let enumerator = clipsDir.enumerate_children('standard::name', Gio.FileQueryInfoFlags.NONE, null);
                let info;
                while ((info = enumerator.next_file(null)) !== null) {
                    let name = info.get_name();
                    let lastDot = name.lastIndexOf('.');
                    if (lastDot < 1) {
                        continue;
                    }

                    let stem = name.slice(0, lastDot);
                    let ext = name.slice(lastDot + 1).toLowerCase();
                    if (!AUDIO_EXTS.includes(ext)) {
                        continue;
                    }

                    if (normalizeClipName(stem) === normalizeClipName(baseName)) {
                        this._audioPlayer.play(clipsDir.get_child(name).get_uri());
                        return;
                    }
                }
            } catch (e) {
                console.error(`Failed to enumerate built-in clips in ${clipsDir.get_path()}: ${e}`);
            }
        }

        console.error(`Built-in clip not found for base name: ${baseName}`);
    }

    _getBuiltInClipDirs() {
        let assetDir = this._extension.dir.get_child('assets');
        let importedDir = Gio.File.new_for_path(
            GLib.build_filenamev([GLib.get_user_data_dir(), 'boris-bar', BUILTIN_CLIPS_DIR])
        );

        return [
            importedDir,
            assetDir.get_child('clips'),
            assetDir.get_child('clips').get_child('Archive'),
        ];
    }

    _getCustomDir() {
        let dirPath = GLib.build_filenamev([GLib.get_user_data_dir(), 'boris-bar', 'custom']);
        let dir = Gio.File.new_for_path(dirPath);
        if (!dir.query_exists(null)) {
            try {
                dir.make_directory_with_parents(null);
            } catch (e) {
                console.error("Failed to create custom directory: " + e);
            }
        }
        return dir;
    }

    _loadCustomClips() {
        let dir = this._getCustomDir();
        let clips = [];
        if (!dir.query_exists(null)) return clips;
        
        try {
            let enumerator = dir.enumerate_children('standard::name', Gio.FileQueryInfoFlags.NONE, null);
            let info;
            while ((info = enumerator.next_file(null)) !== null) {
                let name = info.get_name();
                let ext = name.split('.').pop().toLowerCase();
                if (AUDIO_EXTS.includes(ext)) {
                    clips.push(dir.get_child(name));
                }
            }
        } catch (e) {
            console.error(e);
        }
        clips.sort((a, b) => a.get_basename().localeCompare(b.get_basename()));
        return clips;
    }

    _openCustomDir() {
        let dir = this._getCustomDir();
        Gio.AppInfo.launch_default_for_uri(dir.get_uri(), null);
    }

    playClipIndex(index) {
        if (index >= 0 && index < BUILTIN_CLIPS.length) {
            this._playBuiltIn(BUILTIN_CLIPS[index].base);
        }
    }

    destroy() {
        if (this._audioPlayer) {
            this._audioPlayer.destroy();
            this._audioPlayer = null;
        }
        super.destroy();
    }
});

export default class BorisBarExtension extends Extension {
    enable() {
        this._indicator = new BorisBarIndicator(this);
        Main.panel.addToStatusArea(this.uuid, this._indicator);

        this._settings = this.getSettings();

        // Bind shortcuts
        for (let i = 0; i < 9; i++) {
            Main.wm.addKeybinding(
                `clip-${i + 1}`,
                this._settings,
                Meta.KeyBindingFlags.NONE,
                Shell.ActionMode.ALL,
                () => {
                    this._indicator.playClipIndex(i);
                }
            );
        }
    }

    disable() {
        for (let i = 0; i < 9; i++) {
            Main.wm.removeKeybinding(`clip-${i + 1}`);
        }

        this._settings = null;
        if (this._indicator) {
            this._indicator.destroy();
            this._indicator = null;
        }
    }
}
