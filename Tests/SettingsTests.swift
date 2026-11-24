import AppKit
import Testing
@testable import PointerOverlay

@MainActor
@Suite struct SettingsTests {
    /// テストごとに独立した UserDefaults を使う。
    private func makeDefaults() -> UserDefaults {
        let name = "PointerOverlayTests.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    @Test func firstLaunchDefaults() {
        let s = AppSettings(defaults: makeDefaults())
        #expect(s.size == 80)
        #expect(s.colorHex == "#808080")
        #expect(s.opacity == 100)
        #expect(s.isEnabled == false)
        #expect(s.isAppearanceDefault)
    }

    @Test func valuesAreClampedAndRounded() {
        let s = AppSettings(defaults: makeDefaults())
        s.setSize(10); #expect(s.size == 24)
        s.setSize(1000); #expect(s.size == 300)
        s.setSize(123.6); #expect(s.size == 124)
        s.setSize(.nan); #expect(s.size == 80)
        s.setOpacity(-5); #expect(s.opacity == 0)
        s.setOpacity(150); #expect(s.opacity == 100)
        s.setOpacity(49.5); #expect(s.opacity == 50)
        #expect(s.alpha == 0.5)
    }

    @Test func persistsAndRestoresAcrossInstances() {
        let d = makeDefaults()
        let a = AppSettings(defaults: d)
        a.setSize(200)
        a.setOpacity(40)
        a.setColor(NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1))
        a.setEnabled(true)

        let b = AppSettings(defaults: d)
        #expect(b.size == 200)
        #expect(b.opacity == 40)
        #expect(b.colorHex == "#FF0000")
        #expect(b.isEnabled == true)   // 前回の ON/OFF を復元
    }

    @Test func invalidStoredValuesFallBackSafely() {
        let d = makeDefaults()
        d.set(9999.0, forKey: AppSettings.Key.size)
        d.set("not-a-color", forKey: AppSettings.Key.colorHex)
        d.set(-20.0, forKey: AppSettings.Key.opacity)
        let s = AppSettings(defaults: d)
        #expect(s.size == 300)
        #expect(s.colorHex == "#808080")
        #expect(s.opacity == 0)
    }

    @Test func resetRestoresAppearanceButKeepsEnabled() {
        let d = makeDefaults()
        let s = AppSettings(defaults: d)
        s.setEnabled(true)
        s.setSize(30)
        s.setOpacity(10)
        s.setColor(.blue)
        s.resetAppearance()
        #expect(s.isAppearanceDefault)
        #expect(s.isEnabled)
        #expect(AppSettings(defaults: d).isAppearanceDefault)
    }

    @Test func onChangeFiresOnlyOnActualChange() {
        let s = AppSettings(defaults: makeDefaults())
        var count = 0
        s.onChange = { count += 1 }
        s.setSize(80)        // 同値
        s.setSize(81)
        s.setSize(81)        // 同値
        s.setOpacity(100)    // 同値
        s.setEnabled(false)  // 同値
        s.setEnabled(true)
        #expect(count == 2)
    }

    @Test func hexConversion() {
        #expect(AppSettings.normalizedHex("#80ff00") == "#80FF00")
        #expect(AppSettings.normalizedHex("80FF00") == "#80FF00")
        #expect(AppSettings.normalizedHex("#80FF0") == nil)
        #expect(AppSettings.normalizedHex("#GGGGGG") == nil)
        let c = AppSettings.color(fromHex: "#336699")!
        #expect(AppSettings.hex(from: c) == "#336699")
        // アルファは無視される
        #expect(AppSettings.hex(from: c.withAlphaComponent(0.3)) == "#336699")
    }
}
