import CoreGraphics
import Testing
@testable import PointerOverlay

@Suite struct GeometryTests {
    typealias G = ArrowGeometry

    @Test(arguments: [24.0, 80.0, 300.0])
    func pathHeightMatchesSetting(height: Double) {
        let box = G.path(height: height, tip: .zero).boundingBoxOfPath
        #expect(abs(box.height - height) < 1e-9)
        #expect(abs(box.minX) < 1e-9)
        #expect(abs(box.minY) < 1e-9)
    }

    @Test(arguments: [24.0, 80.0, 300.0])
    func arrowFitsInsideWindow(height: Double) {
        let box = G.path(height: height).boundingBoxOfPath
        let size = G.windowSize(height: height)
        #expect(box.minX == G.padding && box.minY == G.padding)
        #expect(box.maxX <= size.width - G.padding + 1)
        #expect(box.maxY <= size.height - G.padding + 1)
        #expect(size.width == size.width.rounded() && size.height == size.height.rounded())
    }

    /// ウィンドウ左上から (padding, padding) がホットスポットに 0.5 pt 以内で一致し、原点は整数 pt。
    @Test(arguments: [
        CGPoint(x: 100, y: 200),
        CGPoint(x: 895.8046875, y: 713.296875),
        CGPoint(x: -1920, y: -300.5),   // 負座標のサブディスプレイ
        CGPoint(x: 3839.5, y: 2159.25),
    ])
    func windowFrameAlignsHotspot(hotspot: CGPoint) {
        for height in [24.0, 80.0, 300.0] {
            let f = G.windowFrame(hotspot: hotspot, height: height)
            #expect(f.size == G.windowSize(height: height))
            #expect(f.minX == f.minX.rounded() && f.minY == f.minY.rounded())
            #expect(abs(f.minX + G.padding - hotspot.x) <= 0.5)
            #expect(abs(f.maxY - G.padding - hotspot.y) <= 0.5)
        }
    }

    @Test func aspectRatioIsStable() {
        let a = G.arrowSize(height: 24)
        let b = G.arrowSize(height: 300)
        #expect(abs(a.width / a.height - b.width / b.height) < 1e-12)
    }

    // MARK: - 画面への収め方

    let main = CGRect(x: 0, y: 0, width: 1470, height: 956)
    let left = CGRect(x: -1920, y: -200, width: 1920, height: 1080)   // 負座標の外部画面
    let right = CGRect(x: 1470, y: 0, width: 2560, height: 1440)

    @Test func screenLookupIncludesTopEdgeAndNegativeCoordinates() {
        let screens = [main, left, right]
        #expect(G.screenFrame(containing: CGPoint(x: 10, y: 956), in: screens) == main)       // 上端 y == maxY
        #expect(G.screenFrame(containing: CGPoint(x: -10, y: -100), in: screens) == left)
        #expect(G.screenFrame(containing: CGPoint(x: 1470, y: 500), in: screens) == right)   // 境界は右の画面
        #expect(G.screenFrame(containing: CGPoint(x: 1469.9, y: 500), in: screens) == main)
        #expect(G.screenFrame(containing: CGPoint(x: 500, y: 2000), in: screens) == main)    // 外れたら最寄り
        #expect(G.screenFrame(containing: .zero, in: []) == nil)
    }

    @Test func noClippingInsideScreen() {
        let p = G.placement(hotspot: CGPoint(x: 500, y: 500), height: 80, screen: main)
        #expect(p.frame == G.windowFrame(hotspot: CGPoint(x: 500, y: 500), height: 80))
        #expect(p.tip == CGPoint(x: G.padding, y: G.padding))
    }

    /// 右端：隣の画面にはみ出さず、先端の描画位置は変わらない（再描画不要）。
    @Test func clipsAtRightEdgeKeepingTip() {
        let hot = CGPoint(x: 1460, y: 500)
        let p = G.placement(hotspot: hot, height: 300, screen: main)
        #expect(main.contains(p.frame))
        #expect(p.frame.maxX == main.maxX)
        #expect(p.tip == CGPoint(x: G.padding, y: G.padding))
    }

    /// 下端：下の画面にはみ出さない。
    @Test func clipsAtBottomEdge() {
        let p = G.placement(hotspot: CGPoint(x: 500, y: 20), height: 300, screen: main)
        #expect(p.frame.minY == main.minY)
        #expect(p.tip == CGPoint(x: G.padding, y: G.padding))
    }

    /// 左上隅：余白分だけ切り詰め、先端の描画位置で補正してホットスポットを保つ。
    @Test func clipsAtTopLeftCornerAndShiftsTip() {
        let hot = CGPoint(x: -1920, y: 880)   // 左画面の左上隅
        let p = G.placement(hotspot: hot, height: 80, screen: left)
        #expect(left.contains(p.frame))
        // ビュー内の先端位置をグローバル座標に戻すとホットスポットに一致する
        #expect(abs(p.frame.minX + p.tip.x - hot.x) <= 0.5)
        #expect(abs(p.frame.maxY - p.tip.y - hot.y) <= 0.5)
    }
}
