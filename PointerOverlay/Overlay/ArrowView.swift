import AppKit

/// 矢印をベクター描画するビュー。形状・色の変更時のみ再描画する。
final class ArrowView: NSView {
    var arrowHeight: CGFloat = 80 {
        didSet { if arrowHeight != oldValue { cachedPath = nil; needsDisplay = true } }
    }
    var fillColor: NSColor = .gray {
        didSet { if fillColor != oldValue { needsDisplay = true } }
    }

    private var cachedPath: CGPath?

    override var isFlipped: Bool { true }   // 形状座標系（y 下向き）に合わせる
    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let path = cachedPath ?? ArrowGeometry.path(height: arrowHeight)
        cachedPath = path
        ctx.clear(bounds)
        ctx.addPath(path)
        ctx.setFillColor(fillColor.cgColor)
        ctx.fillPath()
    }
}
