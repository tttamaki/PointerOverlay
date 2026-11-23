import AppKit

/// エントリポイント。Dock非表示（LSUIElement）のメニューバー常駐アプリとして AppKit で起動する。
@main
enum PointerOverlayApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
