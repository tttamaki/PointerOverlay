import AppKit
import SwiftUI

/// 設定画面：サイズ・色・不透明度・プレビュー・初期値に戻す。変更は即時反映・保存される。
struct SettingsView: View {
    let settings: AppSettings

    private static let previewSide: CGFloat = 320

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            preview

            Form {
                LabeledContent("サイズ") {
                    HStack {
                        Slider(value: sizeBinding, in: AppSettings.sizeRange, step: 1)
                        TextField("", value: sizeBinding, format: .number.precision(.fractionLength(0)))
                            .frame(width: 52)
                            .multilineTextAlignment(.trailing)
                        Stepper("", value: sizeBinding, in: AppSettings.sizeRange, step: 1)
                            .labelsHidden()
                        Text("pt").foregroundStyle(.secondary)
                    }
                }

                LabeledContent("色") {
                    HStack {
                        ColorPicker("", selection: colorBinding, supportsOpacity: false)
                            .labelsHidden()
                        Text(settings.colorHex)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }

                LabeledContent("不透明度") {
                    HStack {
                        Slider(value: opacityBinding, in: AppSettings.opacityRange, step: 1)
                        Text("\(Int(settings.opacity))%")
                            .monospacedDigit()
                            .frame(width: 44, alignment: .trailing)
                    }
                }
            }

            HStack {
                Spacer()
                Button("初期値に戻す") { settings.resetAppearance() }
                    .disabled(settings.isAppearanceDefault)
            }
        }
        .padding(20)
        .frame(width: Self.previewSide + 40)
    }

    /// 実寸プレビュー（最大 300 pt が収まる大きさ）。透明度が分かるよう市松模様の上に描く。
    private var preview: some View {
        let s = ArrowGeometry.arrowSize(height: settings.size)
        return ZStack(alignment: .topLeading) {
            Checkerboard()
            Path(ArrowGeometry.path(height: settings.size, tip: .zero))
                .fill(Color(nsColor: settings.color).opacity(settings.alpha))
                .frame(width: s.width, height: s.height)
                .padding(10)
        }
        .frame(width: Self.previewSide, height: Self.previewSide)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.separator))
        .accessibilityLabel("矢印プレビュー")
    }

    private var sizeBinding: Binding<Double> {
        Binding(get: { settings.size }, set: { settings.setSize($0) })
    }

    private var opacityBinding: Binding<Double> {
        Binding(get: { settings.opacity }, set: { settings.setOpacity($0) })
    }

    private var colorBinding: Binding<Color> {
        Binding(get: { Color(nsColor: settings.color) }, set: { settings.setColor(NSColor($0)) })
    }
}

private struct Checkerboard: View {
    var body: some View {
        Canvas { ctx, size in
            let cell: CGFloat = 16
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(white: 0.95)))
            for row in 0..<Int(size.height / cell) + 1 {
                for col in 0..<Int(size.width / cell) + 1 where (row + col).isMultiple(of: 2) {
                    ctx.fill(Path(CGRect(x: CGFloat(col) * cell, y: CGFloat(row) * cell, width: cell, height: cell)),
                             with: .color(Color(white: 0.82)))
                }
            }
        }
    }
}

/// 設定ウィンドウ。1 枚だけ作り、再表示時は前面に出す。
@MainActor
final class SettingsWindowController {
    private var window: NSWindow?
    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    func show() {
        if window == nil {
            let w = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(settings: settings)))
            w.title = "Pointer Overlay 設定"
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            w.center()
            window = w
        }
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }
}
