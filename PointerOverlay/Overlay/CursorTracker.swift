import AppKit

/// `NSEvent.mouseLocation` の低頻度ポーリング。位置が変わったときだけ通知する。
@MainActor
final class CursorTracker {
    /// ポーリング周期（内部定数。ユーザー設定には公開しない）。
    static let interval: TimeInterval = 0.05

    private var timer: Timer?
    private var lastLocation: CGPoint?
    private let onMove: (CGPoint) -> Void

    init(onMove: @escaping (CGPoint) -> Void) {
        self.onMove = onMove
    }

    var isRunning: Bool { timer != nil }

    func start() {
        guard timer == nil else { return }  // 多重起動しない
        lastLocation = nil
        let t = Timer(timeInterval: Self.interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        t.tolerance = Self.interval * 0.1
        RunLoop.main.add(t, forMode: .common)  // メニュー操作中・ドラッグ中も追従する
        timer = t
        tick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        lastLocation = nil
    }

    /// 位置が同じでも次の tick で必ず通知させる（画面構成変更時など）。
    func invalidateLastLocation() {
        lastLocation = nil
    }

    private func tick() {
        let p = NSEvent.mouseLocation
        guard p != lastLocation else { return }
        lastLocation = p
        onMove(p)
    }
}
