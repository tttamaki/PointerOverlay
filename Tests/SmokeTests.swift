import Testing
@testable import PointerOverlay

@Suite struct SmokeTests {
    @Test func appModuleLoads() {
        #expect(Bool(true))
    }
}
