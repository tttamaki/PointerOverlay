import CoreGraphics

/// 矢印の形状とウィンドウ配置の計算（純粋関数のみ。テスト対象）。
///
/// 形状座標系：y 下向き、先端（ホットスポット）が原点。
enum ArrowGeometry {
    /// 軸付き標準カーソル型の輪郭（単位座標）。先端から反時計回り（y下向きで見て）。
    static let unitPoints: [CGPoint] = [
        CGPoint(x: 0.0, y: 0.0),   // 先端
        CGPoint(x: 0.0, y: 16.0),  // 左辺の下端
        CGPoint(x: 4.2, y: 12.2),  // 軸の付け根（左）
        CGPoint(x: 7.0, y: 18.6),  // 軸の先（左）
        CGPoint(x: 9.6, y: 17.5),  // 軸の先（右）
        CGPoint(x: 6.8, y: 11.2),  // 軸の付け根（右）
        CGPoint(x: 12.0, y: 11.2), // 右の翼端
    ]
    static let unitHeight: CGFloat = 18.6
    static let unitWidth: CGFloat = 12.0

    /// 描画のアンチエイリアスが切れないよう、ウィンドウ内で矢印の周囲に取る余白（pt）。
    static let padding: CGFloat = 2

    /// 高さ（設定上のサイズ）から矢印の外接矩形サイズを求める。
    static func arrowSize(height: CGFloat) -> CGSize {
        CGSize(width: unitWidth * height / unitHeight, height: height)
    }

    /// 先端を `tip` に置いた矢印のパス（y 下向き座標系）。
    static func path(height: CGFloat, tip: CGPoint = CGPoint(x: padding, y: padding)) -> CGPath {
        let scale = height / unitHeight
        let path = CGMutablePath()
        path.addLines(between: unitPoints.map {
            CGPoint(x: tip.x + $0.x * scale, y: tip.y + $0.y * scale)
        })
        path.closeSubpath()
        return path
    }

    /// オーバーレイウィンドウのコンテンツサイズ（余白込み）。
    static func windowSize(height: CGFloat) -> CGSize {
        let s = arrowSize(height: height)
        return CGSize(width: s.width + padding * 2, height: s.height + padding * 2)
    }

    /// ホットスポット（グローバル画面座標、AppKit の y 上向き）からウィンドウ frame を求める。
    /// 先端はウィンドウ左上から (padding, padding) の位置に描かれる。
    static func windowFrame(hotspot: CGPoint, height: CGFloat) -> CGRect {
        let size = windowSize(height: height)
        let origin = CGPoint(x: hotspot.x - padding,
                             y: hotspot.y + padding - size.height)
        return CGRect(origin: origin, size: size)
    }
}
