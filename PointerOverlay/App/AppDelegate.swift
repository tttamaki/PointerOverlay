import AppKit

/// メニューバー項目、起動・終了を担当する。
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let toggleItem = NSMenuItem(title: "ポインタ表示", action: nil, keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "cursorarrow", accessibilityDescription: "Pointer Overlay")
        item.menu = makeMenu()
        statusItem = item
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        toggleItem.target = self
        toggleItem.action = #selector(toggleOverlay(_:))
        toggleItem.state = .off
        menu.addItem(toggleItem)

        let settingsItem = NSMenuItem(title: "設定…", action: nil, keyEquivalent: "")
        settingsItem.isEnabled = false // Phase 2 で実装
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "終了", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        quitItem.target = NSApp
        menu.addItem(quitItem)
        return menu
    }

    @objc private func toggleOverlay(_ sender: NSMenuItem) {
        // Phase 1 でオーバーレイの表示・非表示に接続する。
        sender.state = (sender.state == .on) ? .off : .on
    }
}
