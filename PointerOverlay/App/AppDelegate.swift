import AppKit

/// メニューバー項目、起動・終了を担当する。
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private let settings = AppSettings()
    private let overlay = OverlayController()
    private lazy var settingsWindow = SettingsWindowController(settings: settings)
    private let toggleItem = NSMenuItem(title: "ポインタ表示", action: nil, keyEquivalent: "")
    private let debugMenu = NSMenu(title: "検証")

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "cursorarrow", accessibilityDescription: "Pointer Overlay")
        item.menu = makeMenu()
        statusItem = item

        settings.onChange = { [weak self] in self?.applySettings() }
        applySettings()   // 前回の ON/OFF・外観を復元（初回は OFF）
    }

    private func applySettings() {
        overlay.apply(enabled: settings.isEnabled,
                      height: settings.size,
                      color: settings.color,
                      opacity: settings.alpha)
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        toggleItem.target = self
        toggleItem.action = #selector(toggleOverlay(_:))
        menu.addItem(toggleItem)

        let settingsItem = NSMenuItem(title: "設定…", action: #selector(showSettings(_:)), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)

        #if DEBUG
        // 検証用（Debug ビルドのみ）：ウィンドウレベルと collectionBehavior の比較
        let debugItem = NSMenuItem(title: "検証", action: nil, keyEquivalent: "")
        debugItem.submenu = debugMenu
        menu.addItem(debugItem)
        #endif

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "終了", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        quitItem.target = NSApp
        menu.addItem(quitItem)
        return menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        toggleItem.state = settings.isEnabled ? .on : .off
        #if DEBUG
        rebuildDebugMenu()
        #endif
    }

    private func rebuildDebugMenu() {
        debugMenu.removeAllItems()
        debugMenu.addItem(withTitle: "ウィンドウレベル", action: nil, keyEquivalent: "").isEnabled = false
        for l in OverlayLevel.allCases {
            let mi = NSMenuItem(title: "  \(l.rawValue) (\(l.level.rawValue))", action: #selector(selectLevel(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = l.rawValue
            mi.state = overlay.level == l ? .on : .off
            debugMenu.addItem(mi)
        }
        debugMenu.addItem(.separator())
        debugMenu.addItem(withTitle: "collectionBehavior", action: nil, keyEquivalent: "").isEnabled = false
        for b in SpaceBehavior.allCases {
            let mi = NSMenuItem(title: "  \(b.rawValue)", action: #selector(selectBehavior(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = b.rawValue
            mi.state = overlay.spaceBehavior == b ? .on : .off
            debugMenu.addItem(mi)
        }
    }

    @objc private func toggleOverlay(_ sender: NSMenuItem) {
        settings.setEnabled(!settings.isEnabled)
    }

    @objc private func showSettings(_ sender: NSMenuItem) {
        settingsWindow.show()
    }

    @objc private func selectLevel(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String, let l = OverlayLevel(rawValue: raw) {
            overlay.level = l
        }
    }

    @objc private func selectBehavior(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String, let b = SpaceBehavior(rawValue: raw) {
            overlay.spaceBehavior = b
        }
    }
}
