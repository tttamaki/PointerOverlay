import CoreGraphics

/// 矢印の形状とウィンドウ配置の計算（純粋関数のみ。テスト対象）。
///
/// 形状座標系：y 下向き、先端（ホットスポット）が原点。
/// 画面座標系：AppKit のグローバル座標（y 上向き、主画面の左下が原点）。
enum ArrowGeometry {
    /// 軸付き標準カーソル型の輪郭（単位座標）。
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

    /// オーバーレイウィンドウのコンテンツサイズ（余白込み、整数 pt に切り上げ）。
    static func windowSize(height: CGFloat) -> CGSize {
        let s = arrowSize(height: height)
        return CGSize(width: (s.width + padding * 2).rounded(.up),
                      height: (s.height + padding * 2).rounded(.up))
    }

    /// ホットスポットからウィンドウ frame を求める（画面による切り詰めなし）。
    /// 原点は整数 pt に丸める（WindowServer が端数を切り捨てるため、最近接に寄せて誤差を 0.5 pt 以内にする）。
    static func windowFrame(hotspot: CGPoint, height: CGFloat) -> CGRect {
        let size = windowSize(height: height)
        let origin = CGPoint(x: (hotspot.x - padding).rounded(),
                             y: (hotspot.y + padding - size.height).rounded())
        return CGRect(origin: origin, size: size)
    }

    /// 配置結果：ウィンドウ frame と、ビュー内（y 下向き）での矢印先端の描画位置。
    struct Placement: Equatable {
        var frame: CGRect
        var tip: CGPoint
    }

    /// マウスのある画面にウィンドウを収める配置を求める。
    ///
    /// 画面をまたぐウィンドウは「重なりの大きい画面」にだけ表示されることがあるため、
    /// ホットスポットのある画面の範囲に切り詰め、先端の描画位置で補正する。
    /// 切り詰めが無いとき `tip` は常に (padding, padding) なので、追従中の再描画は発生しない。
    static func placement(hotspot: CGPoint, height: CGFloat, screen: CGRect?) -> Placement {
        let full = windowFrame(hotspot: hotspot, height: height)
        let defaultTip = CGPoint(x: padding, y: padding)
        guard let screen else { return Placement(frame: full, tip: defaultTip) }
        let clipped = full.intersection(screen)
        guard !clipped.isNull, !clipped.isEmpty, clipped != full else {
            return Placement(frame: full, tip: defaultTip)
        }
        let tip = CGPoint(x: padding - (clipped.minX - full.minX),
                          y: padding - (full.maxY - clipped.maxY))
        return Placement(frame: clipped, tip: tip)
    }

    /// 点を含む画面の frame を返す。
    /// `NSEvent.mouseLocation` は上端で y == maxY になり得るため、y は (minY, maxY] で判定する。
    /// どの画面にも含まれない場合は最も近い画面を返す。
    static func screenFrame(containing p: CGPoint, in screens: [CGRect]) -> CGRect? {
        if let s = screens.first(where: { p.x >= $0.minX && p.x < $0.maxX && p.y > $0.minY && p.y <= $0.maxY }) {
            return s
        }
        return screens.min { distanceSquared(p, $0) < distanceSquared(p, $1) }
    }

    private static func distanceSquared(_ p: CGPoint, _ r: CGRect) -> CGFloat {
        let dx = max(r.minX - p.x, 0, p.x - r.maxX)
        let dy = max(r.minY - p.y, 0, p.y - r.maxY)
        return dx * dx + dy * dy
    }
}
