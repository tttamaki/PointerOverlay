import AppKit

/// メニューバー項目、起動・終了を担当する。
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private let overlay = OverlayController()
    private let toggleItem = NSMenuItem(title: "ポインタ表示", action: nil, keyEquivalent: "")
    private let debugMenu = NSMenu(title: "検証")

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "cursorarrow", accessibilityDescription: "Pointer Overlay")
        item.menu = makeMenu()
        statusItem = item

        // 検証用：`open PointerOverlay.app --args -debug.startEnabled YES` で ON の状態で起動する。
        if UserDefaults.standard.bool(forKey: "debug.startEnabled") {
            overlay.setEnabled(true)
        }
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        toggleItem.target = self
        toggleItem.action = #selector(toggleOverlay(_:))
        menu.addItem(toggleItem)

        let settingsItem = NSMenuItem(title: "設定…", action: nil, keyEquivalent: "")
        settingsItem.isEnabled = false // Phase 2 で実装
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
        toggleItem.state = overlay.isEnabled ? .on : .off
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
        overlay.setEnabled(!overlay.isEnabled)
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
