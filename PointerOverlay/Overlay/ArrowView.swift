import AppKit

/// 矢印をベクター描画するビュー。形状・色・先端位置の変更時のみ再描画する。
final class ArrowView: NSView {
    var arrowHeight: CGFloat = 80 {
        didSet { if arrowHeight != oldValue { invalidatePath() } }
    }
    var fillColor: NSColor = .gray {
        didSet { if fillColor != oldValue { needsDisplay = true } }
    }
    /// ビュー内（y 下向き）での先端位置。画面端で切り詰めたときだけ (padding, padding) から変わる。
    var tip = CGPoint(x: ArrowGeometry.padding, y: ArrowGeometry.padding) {
        didSet { if tip != oldValue { invalidatePath() } }
    }

    private var cachedPath: CGPath?

    override var isFlipped: Bool { true }   // 形状座標系（y 下向き）に合わせる
    override var isOpaque: Bool { false }

    override func setFrameSize(_ newSize: NSSize) {
        let changed = newSize != frame.size
        super.setFrameSize(newSize)
        if changed { needsDisplay = true }
    }

    /// 表示倍率の異なる画面へ移ったときに描き直す。
    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let path = cachedPath ?? ArrowGeometry.path(height: arrowHeight, tip: tip)
        cachedPath = path
        ctx.clear(bounds)
        ctx.addPath(path)
        ctx.setFillColor(fillColor.cgColor)
        ctx.fillPath()
    }

    private func invalidatePath() {
        cachedPath = nil
        needsDisplay = true
    }
}
