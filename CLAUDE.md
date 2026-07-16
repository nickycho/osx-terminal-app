# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

用 Xcode 開啟 `TerminalApp.xcodeproj` 後直接 Build & Run（⌘R）。

若 `project.pbxproj` 需要重新生成（例如新增 Swift 檔案後）：
```bash
python3 gen_xcodeproj.py
```
新增 Swift 檔案時，必須同步更新 `gen_xcodeproj.py` 的 `SOURCE_FILES` 清單，然後重新執行上述指令。

## Architecture

macOS terminal emulator，以 SwiftUI + AppKit 實作，底層 PTY/terminal 渲染使用 **SwiftTerm** 套件（`LocalProcessTerminalView`）。

### 核心資料流

```
TerminalAppApp
  └─ TabManager          # 管理所有分頁狀態（ObservableObject，注入全域 environment）
       └─ [UUID: TerminalViewModel]  # 每個分頁對應一個 ViewModel
            └─ TerminalSessionManager  # 持有 LocalProcessTerminalView，管理 PTY 程序
```

- **`TabManager`**（`Models/TabManager.swift`）：ObservableObject，持有 `[TerminalTab]` 及 `[UUID: TerminalViewModel]`。ViewModel 存在 class 內（非 SwiftUI state），避免 View 重建時被釋放。
- **`TerminalViewModel`**（`ViewModels/TerminalViewModel.swift`）：橋接 `TerminalTab`（資料）與 `TerminalSessionManager`（PTY 程序），實作 `TerminalSessionDelegate` 接收 shell 事件。
- **`TerminalSessionManager`**（`Terminal/TerminalSessionManager.swift`）：直接持有 `LocalProcessTerminalView`，透過 `ShellLauncher` 啟動 shell 並注入環境變數（含 Homebrew PATH）。
- **`TerminalNSViewWrapper`**（`Views/TerminalNSViewWrapper.swift`）：NSViewRepresentable 包裝，將 `LocalProcessTerminalView` 嵌入 SwiftUI。選中時呼叫 `makeFirstResponder` 確保鍵盤輸入正確。

### 快捷鍵系統

- **`ShortcutSettings`**（`Models/ShortcutSettings.swift`）：以 `UserDefaults` 持久化各 `ShortcutAction` 對應的按鍵設定。
- **`KeyboardHandler`**（`ViewModels/KeyboardHandler.swift`）：用 `NSEvent.addLocalMonitorForEvents` 攔截 keyDown，比對 `ShortcutSettings` 後執行對應動作。在 `ContentView.onAppear` 啟動，`onDisappear` 停止。

### 排程系統

- **`ScheduleManager`**（`Models/ScheduleManager.swift`）：singleton，每分鐘用 Timer 檢查 cron 排程，符合條件時呼叫 `vm.session.send(text:)` 傳送指令到 terminal。支援一次性（oneTime）和週期性（periodic，標準 5 欄位 cron 語法）兩種模式。
- 排程資料以 JSON 序列化存於 `UserDefaults`（key: `schedule.items`）。

### Views 分層

```
ContentView
  ├─ TabBarView              # 分頁列，含右鍵選單（重新命名、顏色）
  └─ TerminalContainerView   # 用 ZStack 疊所有分頁，只顯示選中的；非選中透明+禁用點擊
       └─ TerminalNSViewWrapper

Settings（獨立 Scene）
  ├─ ShortcutSettingsView / ShortcutRecorderView
  └─ ScheduleListView / ScheduleEditView
```

`ContentView` 用 ZStack 方式保持所有分頁的 `LocalProcessTerminalView` 都存活（不銷毀），切換分頁只改 opacity 和 `allowsHitTesting`，不重建 PTY 程序。
