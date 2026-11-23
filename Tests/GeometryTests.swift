import CoreGraphics
import Testing
@testable import PointerOverlay

@Suite struct GeometryTests {
    @Test(arguments: [24.0, 80.0, 300.0])
    func pathHeightMatchesSetting(height: Double) {
        let box = ArrowGeometry.path(height: height, tip: .zero).boundingBoxOfPath
        #expect(abs(box.height - height) < 1e-9)
        #expect(abs(box.minX) < 1e-9)
        #expect(abs(box.minY) < 1e-9)
    }

    @Test func tipIsAtPaddingInsideWindow() {
        let path = ArrowGeometry.path(height: 80)
        let box = path.boundingBoxOfPath
        #expect(box.minX == ArrowGeometry.padding)
        #expect(box.minY == ArrowGeometry.padding)
    }

    /// ウィンドウ左上から (padding, padding) が y 上向き座標でホットスポットに一致すること。
    @Test(arguments: [
        CGPoint(x: 100, y: 200),
        CGPoint(x: 0, y: 0),
        CGPoint(x: -1920, y: -300.5),   // 負座標のサブディスプレイ
        CGPoint(x: 3839.5, y: 2159),
    ])
    func windowFrameAlignsHotspot(hotspot: CGPoint) {
        for height in [24.0, 80.0, 300.0] {
            let f = ArrowGeometry.windowFrame(hotspot: hotspot, height: height)
            #expect(f.size == ArrowGeometry.windowSize(height: height))
            #expect(f.minX + ArrowGeometry.padding == hotspot.x)
            #expect(f.maxY - ArrowGeometry.padding == hotspot.y)
        }
    }

    @Test func aspectRatioIsStable() {
        let a = ArrowGeometry.arrowSize(height: 24)
        let b = ArrowGeometry.arrowSize(height: 300)
        #expect(abs(a.width / a.height - b.width / b.height) < 1e-12)
    }
}
