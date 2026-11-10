# TerminalApp

TerminalApp is a native macOS terminal app built with SwiftUI, AppKit, and [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm).

## Features

- Multiple terminal tabs with drag-and-drop reordering, custom names, and color labels
- Detachable tabs that can open in separate windows
- Customizable keyboard shortcuts
- One-time and recurring command schedules, including five-field cron expressions
- Appearance settings for terminal font size and scrollback buffer
- English, Traditional Chinese, Japanese, and Korean interface languages
- Automatic language selection from macOS preferences, with English fallback and a setting to choose a language manually

Scheduled commands run in a selected terminal tab on your Mac.

## Requirements

- macOS 14.0 or later
- Xcode 15 or later

## Build and Run

1. Clone the repository:

   ```sh
   git clone https://github.com/nickycho/osx-terminal-app.git
   cd osx-terminal-app
   ```

2. Open `TerminalApp.xcodeproj` in Xcode.
3. Select the `TerminalApp` scheme and press **⌘R**. Xcode resolves the Swift Package Manager dependencies automatically.

To build from Terminal:

```sh
xcodebuild \
  -project TerminalApp.xcodeproj \
  -scheme TerminalApp \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Project File Generation

If you add or remove Swift source files, update the `SOURCE_FILES` list in `gen_xcodeproj.py`, then regenerate the Xcode project:

```sh
python3 gen_xcodeproj.py
```
