import AppKit

/// ウィンドウレベルの候補（既定：statusBar。Phase 1 で PowerPoint/Keynote 全画面での表示を確認済み）。
enum OverlayLevel: String, CaseIterable {
    case floating, statusBar, popUpMenu, screenSaver

    var level: NSWindow.Level {
        switch self {
        case .floating: .floating
        case .statusBar: .statusBar
        case .popUpMenu: .popUpMenu
        case .screenSaver: .screenSaver
        }
    }
}

/// collectionBehavior の候補（既定：allApplicationsAndSpaces。Phase 1 で確認済み）。
enum SpaceBehavior: String, CaseIterable {
    /// .canJoinAllApplications を優先（plan §4.1）
    case allApplications
    /// .canJoinAllApplications + .canJoinAllSpaces
    case allApplicationsAndSpaces
    /// 従来型：.canJoinAllSpaces + .fullScreenAuxiliary
    case allSpacesAuxiliary

    var behavior: NSWindow.CollectionBehavior {
        let common: NSWindow.CollectionBehavior = [.stationary, .ignoresCycle, .fullScreenDisallowsTiling]
        switch self {
        case .allApplications: return common.union([.canJoinAllApplications])
        case .allApplicationsAndSpaces: return common.union([.canJoinAllApplications, .canJoinAllSpaces])
        case .allSpacesAuxiliary: return common.union([.canJoinAllSpaces, .fullScreenAuxiliary])
        }
    }
}

/// ON/OFF、オーバーレイの表示と移動、画面構成変更への追従。
@MainActor
final class OverlayController {
    private enum Keys {
        static let level = "debug.overlayLevel"
        static let behavior = "debug.spaceBehavior"
    }

    private(set) var isEnabled = false
    var arrowHeight: CGFloat = 80 { didSet { applyStyle() } }
    var fillColor: NSColor = NSColor(srgbRed: 0x80 / 255, green: 0x80 / 255, blue: 0x80 / 255, alpha: 1) {
        didSet { applyStyle() }
    }
    var opacity: CGFloat = 1.0 { didSet { applyStyle(); updateRunningState() } }

    var level: OverlayLevel {
        didSet { UserDefaults.standard.set(level.rawValue, forKey: Keys.level); window.level = level.level }
    }
    var spaceBehavior: SpaceBehavior {
        didSet {
            UserDefaults.standard.set(spaceBehavior.rawValue, forKey: Keys.behavior)
            window.collectionBehavior = spaceBehavior.behavior
        }
    }

    private let window: OverlayWindow
    private let arrowView = ArrowView()
    private lazy var tracker = CursorTracker { [weak self] p in self?.move(to: p) }
    private var observers: [NSObjectProtocol] = []

    init() {
        let defaults = UserDefaults.standard
        level = defaults.string(forKey: Keys.level).flatMap(OverlayLevel.init) ?? .statusBar
        spaceBehavior = defaults.string(forKey: Keys.behavior).flatMap(SpaceBehavior.init) ?? .allApplicationsAndSpaces

        window = OverlayWindow(contentSize: ArrowGeometry.windowSize(height: 80))
        window.setFrame(ArrowGeometry.windowFrame(hotspot: NSEvent.mouseLocation, height: 80), display: false)
        window.contentView = arrowView
        window.level = level.level
        window.collectionBehavior = spaceBehavior.behavior
        applyStyle()
        observeSystem()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        updateRunningState()
    }

    // MARK: - Private

    private var shouldRun: Bool { isEnabled && opacity > 0 }

    private func updateRunningState() {
        if shouldRun {
            tracker.start()
            window.orderFrontRegardless()
        } else {
            tracker.stop()
            window.orderOut(nil)
        }
    }

    private func applyStyle() {
        arrowView.arrowHeight = arrowHeight
        arrowView.fillColor = fillColor.withAlphaComponent(opacity)
        if shouldRun { move(to: NSEvent.mouseLocation) }
    }

    private func move(to hotspot: CGPoint) {
        let screen = ArrowGeometry.screenFrame(containing: hotspot, in: NSScreen.screens.map(\.frame))
        let placement = ArrowGeometry.placement(hotspot: hotspot, height: arrowHeight, screen: screen)
        arrowView.tip = placement.tip
        if window.frame.size == placement.frame.size {
            window.setFrameOrigin(placement.frame.origin)   // 通常時：位置だけ変える
        } else {
            window.setFrame(placement.frame, display: false)
        }
    }

    /// 画面構成変更・スリープ復帰・Space 切り替え時に、位置を再計算して最前面に戻す。
    private func refresh() {
        guard shouldRun else { return }
        tracker.invalidateLastLocation()
        move(to: NSEvent.mouseLocation)
        window.orderFrontRegardless()
    }

    private func observeSystem() {
        let nc = NotificationCenter.default
        let wnc = NSWorkspace.shared.notificationCenter
        let handler: @Sendable (Notification) -> Void = { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        observers.append(nc.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                        object: nil, queue: .main, using: handler))
        observers.append(wnc.addObserver(forName: NSWorkspace.didWakeNotification,
                                         object: nil, queue: .main, using: handler))
        observers.append(wnc.addObserver(forName: NSWorkspace.screensDidWakeNotification,
                                         object: nil, queue: .main, using: handler))
        observers.append(wnc.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification,
                                         object: nil, queue: .main, using: handler))
        observers.append(wnc.addObserver(forName: NSWorkspace.didActivateApplicationNotification,
                                         object: nil, queue: .main, using: handler))
    }
}
