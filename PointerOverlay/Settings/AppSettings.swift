import AppKit
import Observation

/// ユーザー設定。範囲検証・保存・復元・初期値を担当する。
///
/// 値の変更は必ず `set…` メソッドを通す（範囲外の値を保存しないため）。
@MainActor
@Observable
final class AppSettings {
    nonisolated static let sizeRange: ClosedRange<Double> = 24...300
    nonisolated static let opacityRange: ClosedRange<Double> = 0...100

    nonisolated static let defaultSize = 80.0
    nonisolated static let defaultColorHex = "#808080"
    nonisolated static let defaultOpacity = 100.0
    nonisolated static let defaultEnabled = false

    enum Key {
        static let size = "arrowSize"
        static let colorHex = "arrowColor"
        static let opacity = "arrowOpacity"
        static let enabled = "overlayEnabled"
    }

    /// 矢印の外接矩形の高さ（pt、整数）。
    private(set) var size: Double
    /// 矢印の色（sRGB、`#RRGGBB`）。
    private(set) var colorHex: String
    /// 不透明度（%、整数）。
    private(set) var opacity: Double
    /// ポインタ表示の ON/OFF。初回は OFF、以降は前回の状態を復元する。
    private(set) var isEnabled: Bool

    /// 値が変わったときに呼ばれる（オーバーレイへの即時反映用）。
    @ObservationIgnored var onChange: (() -> Void)?
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        size = Self.clampSize(defaults.object(forKey: Key.size) as? Double ?? Self.defaultSize)
        colorHex = (defaults.string(forKey: Key.colorHex)).flatMap(Self.normalizedHex) ?? Self.defaultColorHex
        opacity = Self.clampOpacity(defaults.object(forKey: Key.opacity) as? Double ?? Self.defaultOpacity)
        isEnabled = defaults.object(forKey: Key.enabled) as? Bool ?? Self.defaultEnabled
    }

    var color: NSColor { Self.color(fromHex: colorHex) ?? .gray }
    /// 不透明度 0〜1。
    var alpha: CGFloat { opacity / 100 }

    // MARK: - 変更

    func setSize(_ value: Double) {
        let v = Self.clampSize(value)
        guard v != size else { return }
        size = v
        defaults.set(v, forKey: Key.size)
        onChange?()
    }

    func setColor(_ value: NSColor) {
        guard let hex = Self.hex(from: value), hex != colorHex else { return }
        colorHex = hex
        defaults.set(hex, forKey: Key.colorHex)
        onChange?()
    }

    func setOpacity(_ value: Double) {
        let v = Self.clampOpacity(value)
        guard v != opacity else { return }
        opacity = v
        defaults.set(v, forKey: Key.opacity)
        onChange?()
    }

    func setEnabled(_ value: Bool) {
        guard value != isEnabled else { return }
        isEnabled = value
        defaults.set(value, forKey: Key.enabled)
        onChange?()
    }

    /// サイズ・色・不透明度を初期値に戻す（ON/OFF は変えない）。
    func resetAppearance() {
        size = Self.defaultSize
        colorHex = Self.defaultColorHex
        opacity = Self.defaultOpacity
        for key in [Key.size, Key.colorHex, Key.opacity] { defaults.removeObject(forKey: key) }
        onChange?()
    }

    var isAppearanceDefault: Bool {
        size == Self.defaultSize && colorHex == Self.defaultColorHex && opacity == Self.defaultOpacity
    }

    // MARK: - 検証・変換（nonisolated な純粋関数）

    nonisolated static func clampSize(_ v: Double) -> Double {
        guard v.isFinite else { return defaultSize }
        return min(max(v.rounded(), sizeRange.lowerBound), sizeRange.upperBound)
    }

    nonisolated static func clampOpacity(_ v: Double) -> Double {
        guard v.isFinite else { return defaultOpacity }
        return min(max(v.rounded(), opacityRange.lowerBound), opacityRange.upperBound)
    }

    /// `#RRGGBB`（大文字）に正規化する。不正な文字列なら nil。
    nonisolated static func normalizedHex(_ s: String) -> String? {
        var t = s.trimmingCharacters(in: .whitespaces).uppercased()
        if t.hasPrefix("#") { t.removeFirst() }
        guard t.count == 6, t.allSatisfy(\.isHexDigit) else { return nil }
        return "#" + t
    }

    nonisolated static func color(fromHex s: String) -> NSColor? {
        guard let hex = normalizedHex(s), let v = UInt32(hex.dropFirst(), radix: 16) else { return nil }
        return NSColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255,
                       green: CGFloat((v >> 8) & 0xFF) / 255,
                       blue: CGFloat(v & 0xFF) / 255,
                       alpha: 1)
    }

    /// 色を sRGB の `#RRGGBB` に変換する（アルファは無視）。
    nonisolated static func hex(from color: NSColor) -> String? {
        guard let c = color.usingColorSpace(.sRGB) else { return nil }
        func byte(_ x: CGFloat) -> Int { Int((min(max(x, 0), 1) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", byte(c.redComponent), byte(c.greenComponent), byte(c.blueComponent))
    }
}
