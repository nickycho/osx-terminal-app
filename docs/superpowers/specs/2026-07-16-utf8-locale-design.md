# Terminal 中文檔名 UTF-8 Locale 修正設計

## 問題與根因

Terminal App 能正常顯示 `printf '中文測試\n'`，同一批檔名也能在 macOS 內建終端機正常顯示，因此檔案名稱、SwiftTerm 的 UTF-8 解碼與中文字型渲染都沒有損壞。

問題發生時，App 內 shell 的 `LANG` 是空字串、`LC_CTYPE` 是 `C`。macOS `ls` 在這個 locale 下會把無法表示的非 ASCII 檔名字元輸出為 `?`。以相同 zsh 啟動設定測試時，只要子程序確實收到 UTF-8 locale，啟動後仍會維持 UTF-8；因此修正點是 App 建立 shell 子程序環境的邊界。

## 修正範圍

`ShellLauncher` 應從可注入的基礎環境建立 shell 環境，並無條件將下列值正規化：

- `LANG=zh_TW.UTF-8`
- `LC_ALL=zh_TW.UTF-8`
- `LC_CTYPE=zh_TW.UTF-8`

既有的 `TERM`、`TERM_PROGRAM`、`COLORTERM` 與 Homebrew PATH 行為維持不變。此次不修改使用者的 `~/.zshrc`，也不改動 SwiftTerm 或終端字型。

## 元件與資料流

`ShellLauncher.buildEnvironment` 接受預設為 `ProcessInfo.processInfo.environment` 的基礎環境，覆寫終端與 locale 值後，轉成 SwiftTerm `startProcess` 所需的 `KEY=VALUE` 陣列。`TerminalSessionManager.startShell` 繼續只負責取得環境並啟動 PTY。

可注入基礎環境讓測試不依賴執行測試程序本身的 locale，也能直接覆蓋這次的失敗案例。

## 測試

以獨立 Swift 回歸 harness 驗證 `ShellLauncher`，至少驗證：

1. 基礎環境的 `LANG` 為空字串、`LC_CTYPE=C` 時，輸出仍包含三個正確的 UTF-8 locale 值。
2. 既有 PATH 缺少 Homebrew 路徑時會補上 `/usr/local/bin` 與 `/opt/homebrew/bin`。
3. 輸出仍包含既有的終端能力變數。

測試先在未修正行為下失敗，再進行最小實作使其通過。由於目前產生器只有正式 App target，harness 不加入正式 target，也不改動 `gen_xcodeproj.py`；最後以 `xcodebuild` 建置正式 App。

## 成功標準

- 新啟動的分頁執行 `locale` 時顯示 UTF-8，而不是空的 `LANG` 或 `LC_CTYPE=C`。
- 在含中文檔名的目錄執行 `command ls` 能顯示原始中文，不再顯示 `?`。
- 回歸 harness 與 macOS Debug build 通過。

## 非目標

- 不修改或重新命名使用者檔案。
- 不修改全域 shell 設定。
- 不新增字型選擇或 fallback 功能。
- 不進行與 locale 無關的架構重構。
