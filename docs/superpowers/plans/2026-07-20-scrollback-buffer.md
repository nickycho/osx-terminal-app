# Scrollback Buffer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users choose the scrollback line capacity used by every newly created terminal tab.

**Architecture:** Persist the capacity in `AppearanceSettings`, expose it alongside the existing font-size control, and inject it while `TerminalSessionManager` creates its SwiftTerm view. SwiftTerm reads the capacity when its normal buffer is reset, so only newly constructed sessions use a changed value; existing PTYs and history remain untouched.

**Tech Stack:** Swift 5, SwiftUI, AppKit, XCTest, generated Xcode project, SwiftTerm 1.13.0.

## Global Constraints

- Default capacity is exactly 10,000 lines.
- Valid capacity is 1,000–100,000 lines, in UI increments of 1,000.
- Store the value under `appearance.scrollbackLines` in `UserDefaults`.
- A setting change applies only to newly created terminal tabs.
- Never reset the buffer, terminate the PTY, or alter scrollback for an existing tab.
- New Swift source files must be listed in `gen_xcodeproj.py` before `python3 gen_xcodeproj.py` regenerates the project.
- Preserve the user's unrelated detachable-tab worktree changes.

---

## Files and Responsibilities

- Modify `gen_xcodeproj.py`: generate a `TerminalAppTests` XCTest bundle target, its source group, product reference, build settings, app-target dependency, and shared test scheme.
- Create `TerminalAppTests/ScrollbackBufferTests.swift`: isolated `UserDefaults` tests for the setting plus a SwiftTerm session-initialization regression test.
- Regenerate `TerminalApp.xcodeproj/project.pbxproj` and create `TerminalApp.xcodeproj/xcshareddata/xcschemes/TerminalApp.xcscheme`: generated Xcode metadata required to run `xcodebuild test`.
- Modify `TerminalApp/Models/AppearanceSettings.swift`: own validation, defaulting, persistence, and testable defaults injection for `scrollbackLines`.
- Modify `TerminalApp/Terminal/TerminalSessionManager.swift`: initialize SwiftTerm's normal buffer with the current scrollback setting before a shell starts.
- Modify `TerminalApp/Views/Settings/AppearanceSettingsView.swift`: add the user-facing Stepper and new-tab-only explanation.

### Task 1: Add XCTest infrastructure and a red settings contract

**Files:**
- Create: `TerminalAppTests/ScrollbackBufferTests.swift`
- Modify: `gen_xcodeproj.py`
- Generate: `TerminalApp.xcodeproj/project.pbxproj`
- Generate: `TerminalApp.xcodeproj/xcshareddata/xcschemes/TerminalApp.xcscheme`

**Interfaces:**
- Consumes the planned internal initializer `AppearanceSettings(defaults: UserDefaults)`.
- Produces a `TerminalAppTests` test bundle run by `xcodebuild test -scheme TerminalApp`.

- [ ] **Step 1: Extend the generator with a test-source list and target IDs**

Add these declarations after `SOURCE_FILES` and the existing generated IDs:

```python
TEST_SOURCE_FILES = [
    "ScrollbackBufferTests.swift",
]

TEST_TARGET_ID = uid()
TEST_SOURCE_PHASE_ID = uid()
TEST_FRAMEWORKS_PHASE_ID = uid()
TEST_PRODUCT_ID = uid()
TEST_GROUP_ID = uid()
TEST_CONFIG_LIST_ID = uid()
TEST_DEBUG_ID = uid()
TEST_RELEASE_ID = uid()
TEST_DEPENDENCY_ID = uid()
XCTEST_FILE_ID = uid()
XCTEST_BUILD_FILE_ID = uid()
```

Generate `PBXFileReference`, `PBXBuildFile`, and `PBXGroup` entries for every test source, `TerminalAppTests.xctest`, and `XCTest.framework`. Add the test group to the main group and the test bundle to Products.

- [ ] **Step 2: Generate the runnable test target and scheme**

In `make_pbxproj()`, emit a `PBXNativeTarget` with these exact target properties and build settings:

```text
name = TerminalAppTests;
productName = TerminalAppTests;
productType = "com.apple.product-type.bundle.unit-test";
TEST_HOST = "$(BUILT_PRODUCTS_DIR)/TerminalApp.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/TerminalApp";
BUNDLE_LOADER = "$(TEST_HOST)";
PRODUCT_BUNDLE_IDENTIFIER = com.nickycho.TerminalAppTests;
GENERATE_INFOPLIST_FILE = YES;
MACOSX_DEPLOYMENT_TARGET = 14.0;
SWIFT_VERSION = 5.0;
```

Give it Sources and Frameworks phases, link `XCTest.framework`, and add a `PBXTargetDependency` on the existing `TerminalApp` target. Add the test target to the project `targets` array. Write `TerminalApp.xcscheme` from the generator with a BuildAction for `TerminalApp`, a TestAction containing `TerminalAppTests`, and `Debug` launch/test configurations; interpolate `TARGET_ID`, `TEST_TARGET_ID`, `APP_PRODUCT_ID`, and `TEST_PRODUCT_ID` into the XML so regenerated IDs always agree.

- [ ] **Step 3: Write the failing settings tests**

```swift
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
}
```

- [ ] **Step 4: Regenerate and run the red test**

Run: `python3 gen_xcodeproj.py && xcodebuild test -project TerminalApp.xcodeproj -scheme TerminalApp -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO -only-testing:TerminalAppTests/ScrollbackBufferTests`

Expected: the test target is discovered, then compilation fails because `AppearanceSettings(defaults:)` and `scrollbackLines` do not exist.

- [ ] **Step 5: Preserve pre-existing generator and project edits**

Run: `git status --short gen_xcodeproj.py TerminalApp.xcodeproj/project.pbxproj TerminalAppTests`

Expected: `gen_xcodeproj.py` and `project.pbxproj` are already part of the user's detachable-tab work. Do not stage or commit either mixed file in this task. Leave the generated test infrastructure available in the working tree, stage only `TerminalAppTests/ScrollbackBufferTests.swift` if a standalone test-contract commit is wanted, and report the mixed-file boundary before any commit is attempted.

### Task 2: Implement validated scrollback persistence

**Files:**
- Modify: `TerminalApp/Models/AppearanceSettings.swift`
- Test: `TerminalAppTests/ScrollbackBufferTests.swift`

**Interfaces:**
- Consumes `UserDefaults` passed through `init(defaults:)`.
- Produces `var scrollbackLines: Int`, constrained to `1_000...100_000`, for the settings view and session manager.

- [ ] **Step 1: Implement the settings contract with explicit missing-value handling**

Replace `AppearanceSettings` with this implementation, retaining the existing font-size behavior:

```swift
import Foundation

final class AppearanceSettings: ObservableObject {
    static let shared = AppearanceSettings()

    static let defaultScrollbackLines = 10_000
    static let scrollbackRange = 1_000...100_000

    private let defaults: UserDefaults
    private let fontSizeKey = "appearance.fontSize"
    private let scrollbackLinesKey = "appearance.scrollbackLines"

    @Published var fontSize: Double {
        didSet { defaults.set(fontSize, forKey: fontSizeKey) }
    }

    @Published var scrollbackLines: Int {
        didSet {
            let normalized = Self.normalize(scrollbackLines)
            if scrollbackLines != normalized {
                scrollbackLines = normalized
            } else {
                defaults.set(scrollbackLines, forKey: scrollbackLinesKey)
            }
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let storedFontSize = defaults.double(forKey: fontSizeKey)
        fontSize = storedFontSize > 0 ? storedFontSize : 13

        if let storedScrollback = defaults.object(forKey: scrollbackLinesKey) as? Int {
            scrollbackLines = Self.normalize(storedScrollback)
        } else {
            scrollbackLines = Self.defaultScrollbackLines
        }
    }

    private static func normalize(_ value: Int) -> Int {
        min(max(value, scrollbackRange.lowerBound), scrollbackRange.upperBound)
    }
}
```

- [ ] **Step 2: Run the focused test to verify green**

Run: `xcodebuild test -project TerminalApp.xcodeproj -scheme TerminalApp -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO -only-testing:TerminalAppTests/ScrollbackBufferTests`

Expected: all three `ScrollbackBufferTests` pass.

- [ ] **Step 3: Commit the settings model without staging unrelated work**

```bash
git add TerminalApp/Models/AppearanceSettings.swift
git commit -m "feat: persist scrollback buffer setting"
```

### Task 3: Initialize new terminal buffers with the chosen capacity

**Files:**
- Modify: `TerminalAppTests/ScrollbackBufferTests.swift`
- Modify: `TerminalApp/Terminal/TerminalSessionManager.swift`

**Interfaces:**
- Consumes `TerminalSessionManager(init:)` parameter `scrollbackLines: Int`, defaulting to `AppearanceSettings.shared.scrollbackLines`.
- Produces a new `LocalProcessTerminalView` whose `terminal.options.scrollback` matches the selected capacity before `startShell` can be called.

- [ ] **Step 1: Add the failing session-initialization test**

Append this test to `ScrollbackBufferTests`:

```swift
func testNewSessionConfiguresSwiftTermScrollbackBeforeStartingShell() {
    let session = TerminalSessionManager(scrollbackLines: 25_000)

    XCTAssertEqual(session.terminalView.terminal.options.scrollback, 25_000)
}
```

- [ ] **Step 2: Run the focused test to verify red**

Run: `xcodebuild test -project TerminalApp.xcodeproj -scheme TerminalApp -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO -only-testing:TerminalAppTests/ScrollbackBufferTests/testNewSessionConfiguresSwiftTermScrollbackBeforeStartingShell`

Expected: compilation fails because `TerminalSessionManager` has no `scrollbackLines` initializer parameter.

- [ ] **Step 3: Configure SwiftTerm before process startup**

Change the initializer in `TerminalSessionManager.swift` to:

```swift
init(scrollbackLines: Int = AppearanceSettings.shared.scrollbackLines) {
    terminalView = LocalProcessTerminalView(frame: .zero)
    super.init()
    terminalView.terminal.options.scrollback = scrollbackLines
    terminalView.terminal.setup(isReset: true)
    let size = AppearanceSettings.shared.fontSize
    terminalView.font = Self.makeFont(size: size)
    terminalView.processDelegate = self
    terminalView.configureNativeColors()
    terminalView.translatesAutoresizingMaskIntoConstraints = false
}
```

Do not add an update method or observer: a pre-existing `LocalProcessTerminalView` must retain its own buffer and PTY.

- [ ] **Step 4: Run the focused test to verify green**

Run: `xcodebuild test -project TerminalApp.xcodeproj -scheme TerminalApp -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO -only-testing:TerminalAppTests/ScrollbackBufferTests`

Expected: all four tests pass.

- [ ] **Step 5: Commit the session initialization change**

```bash
git add TerminalApp/Terminal/TerminalSessionManager.swift TerminalAppTests/ScrollbackBufferTests.swift
git commit -m "feat: configure terminal scrollback on new sessions"
```

### Task 4: Expose the setting in the existing Appearance page

**Files:**
- Modify: `TerminalApp/Views/Settings/AppearanceSettingsView.swift`

**Interfaces:**
- Consumes `AppearanceSettings.scrollbackLines`.
- Produces a Stepper whose binding saves the current value and whose explanatory copy states it applies to new tabs.

- [ ] **Step 1: Add the Scrollback Buffer section below font size**

Add this second `Section` to the `Form`:

```swift
Section("終端機") {
    HStack {
        VStack(alignment: .leading, spacing: 2) {
            Text("Scrollback Buffer")
            Text("套用於新分頁")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        Spacer()
        Stepper(
            value: $settings.scrollbackLines,
            in: AppearanceSettings.scrollbackRange,
            step: 1_000
        ) {
            Text("\\(settings.scrollbackLines.formatted()) 行")
                .monospacedDigit()
                .frame(width: 88, alignment: .trailing)
        }
    }
}
```

- [ ] **Step 2: Run the complete automated suite**

Run: `xcodebuild test -project TerminalApp.xcodeproj -scheme TerminalApp -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO`

Expected: `ScrollbackBufferTests` passes with no failures.

- [ ] **Step 3: Build the Debug app**

Run: `xcodebuild build -project TerminalApp.xcodeproj -scheme TerminalApp -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO`

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 4: Manually verify the new-tab boundary**

1. Launch the Debug app and open Settings → 外觀.
2. Set `Scrollback Buffer` to 1,000 and create a new tab.
3. Run `for i in {1..1200}; do echo "$i"; done`, then scroll to confirm early output is retained up to the configured capacity.
4. Change the setting to 10,000 without closing that tab; confirm its shell remains active and its current history is still visible.
5. Create another tab, run `for i in {1..10050}; do echo "$i"; done`, then scroll to confirm the newer capacity applies only there.

- [ ] **Step 5: Review generated and source diffs, then commit only the clean view file**

Run: `git diff --check && git status --short`

Expected: no whitespace errors. Do not stage `gen_xcodeproj.py` or `project.pbxproj`, because each also contains pre-existing detachable-tab work.

```bash
git add TerminalApp/Views/Settings/AppearanceSettingsView.swift
git commit -m "feat: add scrollback buffer preference"
```
