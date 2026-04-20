import Cocoa
import AVFoundation
import ServiceManagement
import Carbon.HIToolbox

struct BuiltInClip {
    let label: String
    let base: String
    let key: UInt32
    let mods: UInt32
    let display: String
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    var player: AVAudioPlayer?
    var currentURL: URL?
    var stopWork: DispatchWorkItem?
    var loginItem: NSMenuItem!
    var hotKeyRefs: [EventHotKeyRef?] = []
    let maxDuration: TimeInterval = 30

    let builtIn: [BuiltInClip] = [
        BuiltInClip(label: "F4",
                    base: "F4",
                    key: UInt32(kVK_ANSI_1), mods: UInt32(cmdKey | optionKey), display: "⌥⌘1"),
        BuiltInClip(label: "Tutti basiti",
                    base: "Tutti basiti",
                    key: UInt32(kVK_ANSI_2), mods: UInt32(cmdKey | optionKey), display: "⌥⌘2"),
        BuiltInClip(label: "A cazzo di cane",
                    base: "a cazzo di cane",
                    key: UInt32(kVK_ANSI_3), mods: UInt32(cmdKey | optionKey), display: "⌥⌘3"),
        BuiltInClip(label: "Fai uno sforzo",
                    base: "fai uno sforzo",
                    key: UInt32(kVK_ANSI_4), mods: UInt32(cmdKey | optionKey), display: "⌥⌘4"),
        BuiltInClip(label: "Fiano Romano",
                    base: "Fiano Romano",
                    key: UInt32(kVK_ANSI_5), mods: UInt32(cmdKey | optionKey), display: "⌥⌘5"),
        BuiltInClip(label: "Però sei molto italiano",
                    base: "Però sei molto italiano",
                    key: UInt32(kVK_ANSI_6), mods: UInt32(cmdKey | optionKey), display: "⌥⌘6"),
        BuiltInClip(label: "Thank you for being so not italian",
                    base: "Thank you for being so not italian",
                    key: UInt32(kVK_ANSI_7), mods: UInt32(cmdKey | optionKey), display: "⌥⌘7"),
        BuiltInClip(label: "Io la mollo questa serie",
                    base: "Io la mollo questa serie",
                    key: UInt32(kVK_ANSI_8), mods: UInt32(cmdKey | optionKey), display: "⌥⌘8"),
        BuiltInClip(label: "Vuoi una pompa",
                    base: "Vuoi una pompa",
                    key: UInt32(kVK_ANSI_9), mods: UInt32(cmdKey | optionKey), display: "⌥⌘9"),
    ]

    let audioExts = ["mp3", "mp4", "m4a", "wav", "aiff", "aif", "caf"]

    // MARK: - Custom sounds dir

    var customDir: URL {
        let app = FileManager.default.urls(for: .applicationSupportDirectory,
                                           in: .userDomainMask)[0]
        let dir = app.appendingPathComponent("BorisBar/custom", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir,
                                                  withIntermediateDirectories: true)
        return dir
    }

    func loadCustomClips() -> [URL] {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: customDir, includingPropertiesForKeys: nil)) ?? []
        return files
            .filter { audioExts.contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() }
    }

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ n: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let btn = statusItem.button, let img = NSImage(named: "fish") {
            img.isTemplate = true    // menu bar: auto white/black tint
            img.size = NSSize(width: 18, height: 18)
            btn.image = img
        }
        rebuildMenu()
        registerHotKeys()
    }

    func rebuildMenu() {
        let menu = NSMenu()
        menu.delegate = self

        for c in builtIn {
            let item = NSMenuItem(title: c.label,
                                  action: #selector(playBuiltIn(_:)),
                                  keyEquivalent: "")
            item.representedObject = c.base
            item.target = self
            let attr = NSMutableAttributedString(string: c.label)
            attr.append(NSAttributedString(string: "\t\(c.display)",
                attributes: [.foregroundColor: NSColor.secondaryLabelColor]))
            item.attributedTitle = attr
            menu.addItem(item)
        }

        let customs = loadCustomClips()
        if !customs.isEmpty {
            menu.addItem(.separator())
            let header = NSMenuItem(title: "Suoni personalizzati",
                                    action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)
            for url in customs {
                let label = url.deletingPathExtension().lastPathComponent
                let item = NSMenuItem(title: label,
                                      action: #selector(playCustom(_:)),
                                      keyEquivalent: "")
                item.representedObject = url
                item.target = self
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())
        let add = NSMenuItem(title: "Aggiungi suono personalizzato…",
                             action: #selector(addCustomSound),
                             keyEquivalent: "")
        add.target = self
        menu.addItem(add)
        let open = NSMenuItem(title: "Apri cartella suoni",
                              action: #selector(openCustomDir),
                              keyEquivalent: "")
        open.target = self
        menu.addItem(open)

        menu.addItem(.separator())
        loginItem = NSMenuItem(title: "Avvia al login",
                               action: #selector(toggleLogin),
                               keyEquivalent: "")
        loginItem.target = self
        menu.addItem(loginItem)
        menu.addItem(withTitle: "Esci",
                     action: #selector(NSApp.terminate),
                     keyEquivalent: "q")

        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        loginItem.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
    }

    // MARK: - Playback

    @objc func playBuiltIn(_ sender: NSMenuItem) {
        guard let base = sender.representedObject as? String else { return }
        playBuiltIn(base: base)
    }

    func playBuiltIn(base: String) {
        for ext in audioExts {
            if let url = Bundle.main.url(forResource: base,
                                         withExtension: ext,
                                         subdirectory: "clips") {
                play(url: url); return
            }
        }
    }

    @objc func playCustom(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        play(url: url)
    }

    func play(url: URL) {
        // Toggle: same clip playing → stop.
        if let p = player, p.isPlaying, currentURL == url {
            stopPlayback()
            return
        }
        stopPlayback()
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return }
        player = p
        currentURL = url
        p.play()
        let work = DispatchWorkItem { [weak self] in self?.stopPlayback() }
        stopWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + maxDuration, execute: work)
    }

    func stopPlayback() {
        stopWork?.cancel()
        stopWork = nil
        player?.stop()
        player = nil
        currentURL = nil
    }

    // MARK: - Custom sound management

    @objc func addCustomSound() {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.title = "Scegli un file audio"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.audio, .mp3, .mpeg4Audio, .wav, .aiff]
        guard panel.runModal() == .OK, let src = panel.url else { return }
        let dst = customDir.appendingPathComponent(src.lastPathComponent)
        do {
            if FileManager.default.fileExists(atPath: dst.path) {
                try FileManager.default.removeItem(at: dst)
            }
            try FileManager.default.copyItem(at: src, to: dst)
        } catch {
            NSLog("Copy failed: \(error)")
        }
        rebuildMenu()
    }

    @objc func openCustomDir() {
        NSWorkspace.shared.open(customDir)
    }

    // MARK: - Login item

    @objc func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("Login toggle failed: \(error)")
        }
    }

    // MARK: - Global hotkeys (Carbon)

    func registerHotKeys() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        InstallEventHandler(GetApplicationEventTarget(), { (_, event, userData) -> OSStatus in
            var hkID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &hkID)
            if let userData = userData {
                let d = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
                let idx = Int(hkID.id)
                if idx >= 0 && idx < d.builtIn.count {
                    d.playBuiltIn(base: d.builtIn[idx].base)
                }
            }
            return noErr
        }, 1, &eventType, selfPtr, nil)

        let signature: OSType = 0x42525342 // 'BRSB'
        for (i, c) in builtIn.enumerated() {
            var ref: EventHotKeyRef?
            let hkID = EventHotKeyID(signature: signature, id: UInt32(i))
            RegisterEventHotKey(c.key, c.mods, hkID, GetApplicationEventTarget(), 0, &ref)
            hotKeyRefs.append(ref)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
