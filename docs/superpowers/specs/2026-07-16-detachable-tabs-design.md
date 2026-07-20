# 可拖出獨立視窗的分頁設計

## 目標

使用者可以從分頁列拖曳分頁到主視窗外，建立一個顯示同一個 terminal session 的獨立 macOS 視窗。獨立視窗關閉時，該分頁與 shell 一起關閉；在主視窗內拖曳仍維持原有的分頁排序。

## 現況與限制

- `TabManager` 持有 `[TerminalTab]` 與 `[UUID: TerminalViewModel]`。
- `TerminalViewModel` 持有 `TerminalSessionManager`，後者持有 SwiftTerm `LocalProcessTerminalView` 與 PTY。
- `ContentView` 用 ZStack 保持所有主視窗分頁的 terminal view 存活。
- `ScheduleManager` 透過 `TabManager.tabs` 與 `viewModels` 尋找目標分頁，因此 detached tab 不能從這兩個集合消失，否則排程會失去目標。

## 採用方案

採用 AppKit 原生拖曳來源搭配獨立 `NSWindow`，不使用新的 SwiftUI `WindowGroup` scene。AppKit 可取得拖曳 session 的結束座標與 operation，能可靠區分「主視窗內排序」與「拖出視窗」。獨立視窗重用同一個 `TerminalViewModel`，因此不會重新建立 shell 或 PTY。

## 狀態模型

### `TerminalTab`

新增 `@Published var isDetached = false`。分頁物件與 `viewModels` 仍保留在 `TabManager`，只由主視窗 UI 過濾 `isDetached == false` 的分頁。

### `TabManager`

新增：

- `attachedTabs`：只回傳主視窗應顯示的分頁。
- `viewModel(for:)`：集中建立並快取每個分頁的 `TerminalViewModel`。
- `detachTab(id:)`：標記 detached，並在選中分頁被拖出時選取下一個 attached tab。

`closeTab(id:)` 維持現有終止 session、移除 view model 與移除 tab 的行為；因此獨立視窗關閉時直接呼叫它即可。

## 拖曳流程

新增 `TabDragSourceView`（`NSViewRepresentable`）與對應 `NSView`：

1. 使用者在分頁左側 drag handle 按下並拖曳。
2. 原生 `NSDraggingSession` 將 tab UUID 放到 `.string` pasteboard，既有 `TabDropDelegate` 可繼續處理主視窗內排序。
3. 拖曳開始時更新 `TabBarView` 的 `draggingTabID`，保留現有半透明視覺提示。
4. 拖曳結束時，若 operation 是 `.move` 或結束座標仍在主視窗內，只清除 dragging state；若 operation 是 `.none` 且座標在主視窗外，呼叫 `TerminalWindowManager.detach(tabID:)`。
5. `TabManager.detachTab` 先更新狀態，再由 window manager 建立獨立視窗，確保主視窗不再持有該 terminal view 的 SwiftUI hierarchy。

## 獨立視窗生命週期

新增 `TerminalWindowManager` 與 `DetachedTerminalWindowController`：

- manager 以 `[UUID: DetachedTerminalWindowController]` 強引用視窗 controller，避免 window 被釋放。
- controller 以 `NSWindowDelegate.windowWillClose` 接收使用者關閉事件。
- 新視窗的 root view 重用 `TerminalContainerView(viewModel:isSelected:)`，並設定最小尺寸與 tab title。
- `windowWillClose` 呼叫 `TabManager.closeTab(id:)`，終止 shell、移除 view model/tab，再從 manager 移除 controller。
- 若 detached session 自己結束，視窗保持既有「進程已結束」 overlay；使用者關閉視窗時仍會清理所有狀態。

`TerminalAppApp` 建立並注入 `TerminalWindowManager`；`ContentView`、`TabBarView` 使用同一個 environment object。

## 錯誤與邊界行為

- 已 detached 的 tab 不可再次建立第二個 detached window。
- 若 tab 尚未有 view model，window manager 透過 `TabManager.viewModel(for:)` 建立並快取，不直接建立第二份。
- 主視窗最後一個 attached tab 被拖出後顯示既有空狀態，不自動建立新 shell。
- 獨立視窗建立失敗時，回復 `isDetached = false`，分頁留在主視窗。
- 關閉 detached window 只關閉該 tab，不影響主視窗其他 PTY。

## 測試與驗證

新增可測試的 `TabManager` 行為測試，驗證：

1. `attachedTabs` 排除 detached tab。
2. `detachTab` 不會替同一 tab 建立第二個 view model。
3. `closeTab` 會移除 tab 與 view model，並觸發 session termination。
4. 拖曳 source 在主視窗外結束時才呼叫 detach callback；主視窗內排序不會 detach。

最後執行 focused tests 與 `xcodebuild build -project TerminalApp.xcodeproj -scheme TerminalApp -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO`。

## 非目標

- 不新增跨視窗 tab merge 或拖回主視窗功能。
- 不改變 shell locale、字型、排程語法或快捷鍵設定。
- 不把 detached tab 顯示在主視窗的 tab bar。
