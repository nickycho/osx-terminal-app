# Scrollback Buffer 設定設計

## 目標

讓使用者在「設定」的「外觀」頁調整每個新終端分頁保留的 scrollback 行數。設定預設為 10,000 行，避免 SwiftTerm 預設 500 行過早捨棄終端輸出。

## 使用者行為

- 「外觀」頁新增 `Scrollback Buffer` Stepper，範圍為 1,000 至 100,000 行、每次調整 1,000 行。
- 設定會立即寫入 `UserDefaults`，但只在之後建立的新分頁套用。
- 已開啟分頁不會重新建立 terminal buffer，因此不會遺失已累積的 scrollback 或中斷 shell 程序。

## 元件與資料流

`AppearanceSettings` 新增 `scrollbackLines` 屬性，以 `appearance.scrollbackLines` 儲存。讀取時將缺少值視為 10,000，並把損壞或超出範圍的值正規化到 1,000 至 100,000。

`AppearanceSettingsView` 綁定這個屬性並顯示目前行數與「套用於新分頁」提示。這項設定沿用既有的外觀分頁，不新增僅有一項設定的分頁。

建立 `TerminalSessionManager` 時，先設定 `LocalProcessTerminalView` 底層 `Terminal` 的 `options.scrollback`，再重設尚未使用的 normal buffer，使容量在 shell 啟動前生效。`TabManager` 建立新的 `TerminalViewModel` 時既有的初始化鏈會自動讀取最新設定；不需要改變分頁、PTY 或視圖生命週期。

## 錯誤處理與相容性

`UserDefaults.integer(forKey:)` 對缺少值回傳 0，因此模型需明確辨識缺少值並採用預設值，不能將其直接限制成最小值。所有有效設定都限制在 UI 相同範圍，避免手動修改 defaults 後配置過大而耗用不必要記憶體。

SwiftTerm 只在 terminal 設定與 buffer 初始化時讀取 scrollback 容量；既有分頁維持其既有容量是刻意行為。

## 測試

新增 XCTest target，針對可注入的 `UserDefaults` 驗證：

1. 缺少值時採用 10,000 行。
2. 設定變更會保存並在新的設定實例中讀回。
3. 小於 1,000 或大於 100,000 的儲存值會正規化到對應邊界。
4. 新建 `TerminalSessionManager` 的底層 `Terminal` 使用已選 scrollback 值。

測試會先在尚未支援該設定時失敗，再做最小實作使其通過。最後以 `xcodebuild` 建置 Debug App，並手動建立新分頁、輸出超過 500 行後向上捲動，確認新容量生效。

## 成功標準

- 預設的新分頁保留 10,000 行 scrollback。
- 使用者可在 1,000–100,000 行間調整，並在重新開啟設定後看到保存值。
- 變更設定不清除或中斷既有分頁。
- 新分頁採用最新設定，單元測試與 Debug build 皆通過。

## 非目標

- 不為每個分頁提供不同 scrollback 容量。
- 不改變既有分頁的容量或重建其 PTY。
- 不新增終端輸出持久化、全文搜尋或磁碟型 history。
