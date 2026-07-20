import XCTest
@testable import TerminalApp

final class ScrollbackBufferTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "ScrollbackBufferTests")!
        defaults.removePersistentDomain(forName: "ScrollbackBufferTests")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "ScrollbackBufferTests")
        defaults = nil
        super.tearDown()
    }

    func testMissingValueDefaultsToTenThousandLines() {
        XCTAssertEqual(AppearanceSettings(defaults: defaults).scrollbackLines, 10_000)
    }

    func testScrollbackLinesPersists() {
        let settings = AppearanceSettings(defaults: defaults)
        settings.scrollbackLines = 42_000

        XCTAssertEqual(AppearanceSettings(defaults: defaults).scrollbackLines, 42_000)
    }

    func testStoredValuesAreClampedToSupportedRange() {
        defaults.set(1, forKey: "appearance.scrollbackLines")
        XCTAssertEqual(AppearanceSettings(defaults: defaults).scrollbackLines, 1_000)

        defaults.set(1_000_000, forKey: "appearance.scrollbackLines")
        XCTAssertEqual(AppearanceSettings(defaults: defaults).scrollbackLines, 100_000)
    }

    func testOutOfRangeAssignmentsPersistNormalizedValues() {
        let settings = AppearanceSettings(defaults: defaults)

        settings.scrollbackLines = 1
        XCTAssertEqual(AppearanceSettings(defaults: defaults).scrollbackLines, 1_000)

        settings.scrollbackLines = 1_000_000
        XCTAssertEqual(AppearanceSettings(defaults: defaults).scrollbackLines, 100_000)
    }

    func testNewSessionConfiguresSwiftTermScrollbackBeforeStartingShell() {
        let session = TerminalSessionManager(scrollbackLines: 25_000)

        XCTAssertEqual(session.terminalView.terminal.options.scrollback, 25_000)
    }
}
