# Mac 與 iOS 工作時間紀錄 App 設計與實作指南

以下指南提供以 SwiftUI 建構一款跨 iPhone／iPad／Mac（Mac Catalyst）／Apple Watch 的工作時間紀錄 App 的實作藍圖，涵蓋資料模型、狀態管理、Google Calendar 整合、離線同步與部署重點。

## 架構選型
- **技術堆疊**：SwiftUI + MVVM，資料層採 SwiftData（iOS 17+/macOS 14+）或 Core Data。背景任務與同步使用 Combine/async-await。
- **跨平台策略**：單一 SwiftUI 程式碼基底，利用 `#if os(macOS)`/`#if os(watchOS)` 進行少量分支。iOS App 以 Mac Catalyst 打包成 macOS 版本；watchOS 提供快速開始/停止的輕量介面。
- **模組劃分**：
  - Models：`TimeEntry`、`Category`、`PendingSyncTask`。
  - ViewModels：`TimerManager`、`TimeEntryListViewModel`、`StatisticsViewModel`、`GoogleCalendarManager`、`SyncCoordinator`。
  - Views：主頁（列表/日曆）、計時器、分類管理、統計、設定、Menu Bar Extra（macOS）、Complication/Live Activity（可選）。
  - Persistence：`PersistenceController`（SwiftData/Core Data 堆疊）。

## 資料模型
```swift
struct TimeEntry: Identifiable {
    var id: UUID
    var start: Date
    var end: Date?
    var note: String
    var categoryID: UUID?
    var syncedToCalendar: Bool
    var calendarEventID: String?
    var lastModified: Date
}

struct Category: Identifiable {
    var id: UUID
    var name: String
    var colorHex: String
    var hourlyRate: Decimal?
    var archived: Bool
}

struct PendingSyncTask: Identifiable {
    enum Action { case insert, update, delete }
    var id: UUID
    var entryID: UUID
    var action: Action
    var payload: Data // JSON 編碼事件資料
    var createdAt: Date
}
```
- `duration` 由 `start`/`end` 計算；進行中條目 `end == nil`。
- `PendingSyncTask` 用於離線累積要同步到雲端/Google Calendar 的事件。

## 計時與狀態管理
- `TimerManager` 使用 `Timer.publish` 或 `Clock`（async sequence）每秒刷新，維持當前計時狀態。
- API：`start(category:note:)`、`pause()`、`resume()`、`stop()`；`stop()` 會寫入 `TimeEntry` 並觸發同步。
- 以 `@StateObject` 供多視圖共享；對 watchOS 可透過 `WCSession` 或 `App Groups` 分享狀態。

## UI 設計
- **主頁**：`TabView` 包含「紀錄」（列表/日曆切換）、`StatisticsView`、`SettingsView`。
- **列表檢視**：`List` 分組顯示日期，Cell 展示分類顏色、開始/結束時間、時長與備註。
- **日曆檢視**：使用 `ScrollViewReader` + `LazyVStack` 模擬時間軸，或集成第三方 SwiftUI Calendar 元件。提供 Google/本地事件混合顯示。
- **計時器面板**：顯示計時字串、分類選擇器、備註輸入、開始/暫停/結束按鈕。macOS 版額外提供 Menu Bar Extra 快捷操作。
- **統計**：圓餅圖或柱狀圖（Charts 框架）展示按分類、專案或時間範圍的統計。
- **可及性**：支援 Dynamic Type、VoiceOver label、色彩對比檢查。

## Google Calendar 整合流程
1. **OAuth 設定**：在 Google Cloud Console 啟用 Calendar API，建立 OAuth Client（iOS/macOS），scope 使用 `https://www.googleapis.com/auth/calendar`。
2. **登入**：以 GoogleSignIn 取得憑證，將 `GTLRCalendarService.authorizer` 指向 `user.authentication.fetcherAuthorizer()`。
3. **建立事件**：停止計時後，組出事件並呼叫 `events.insert()`：
```swift
func insertEvent(for entry: TimeEntry) async throws -> String {
    let event = GTLRCalendar_Event()
    event.summary = entry.note.isEmpty ? "Work" : entry.note
    event.descriptionProperty = "Category: \(entry.categoryName ?? "Uncategorized")"

    let startDate = GTLRDateTime(date: entry.start)
    let endDate = GTLRDateTime(date: entry.end ?? Date())
    event.start = GTLRCalendar_EventDateTime(dateTime: startDate)
    event.end = GTLRCalendar_EventDateTime(dateTime: endDate)

    let query = GTLRCalendarQuery_EventsInsert.query(withObject: event, calendarId: "primary")
    let result = try await service.executeQuery(query) as GTLRCalendar_Event
    return result.identifier ?? ""
}
```
4. **更新/刪除**：使用 `events.update()` 或 `events.delete()`，並利用 `calendarEventID` 對應本地資料。
5. **權限檢查**：對特定日曆需確認 `accessRole` 具寫入權限。

## 離線與同步策略
- 所有寫入先儲存在本地資料庫；若 Google Calendar 未授權或裝置離線，將同步操作序列化為 `PendingSyncTask`。
- 背景排程：
  - iOS：`BGProcessingTaskRequest` 週期性嘗試上傳；前景啟動時也觸發同步。
  - macOS：啟動或間隔計時器觸發同步。
- 同步流程：
  1. 檢查網路與授權；若缺少則保留佇列。
  2. 依 `createdAt` 順序執行 `insert/update/delete` 至 Google Calendar。
  3. 成功後更新 `TimeEntry.syncedToCalendar = true` 並儲存 `calendarEventID`。
  4. 失敗時記錄錯誤與 retry backoff。

## 資料匯出與隱私
- 提供 CSV 匯出（含開始、結束、分類、時長、備註）。
- 在「設定」提供資料刪除、重新授權 Google、選擇同步的日曆、開啟/關閉自動同步。
- 儲存 OAuth token 需使用 Keychain；避免在日曆描述中寫入敏感資訊。

## 測試重點
- 單元測試：`TimerManager` 計時正確性、`SyncCoordinator` 對離線佇列的處理、資料模型序列化。
- 介面測試：啟停計時、分類選擇、統計範圍切換。
- 整合測試：模擬離線建立紀錄、重新上線後寫入 Google Calendar 並核對事件時間。

## 部署與發行
- **組態分層**：以 `xcconfig` 管理不同環境的 Client ID、Feature Flags（如日曆同步開關）。
- **App Groups**：在 iOS + watchOS 間共享資料（或透過 CloudKit 同步條目）。
- **商店審核**：於隱私權頁面說明使用 Google Calendar 資訊僅用於建立/更新事件；提供「停止同步」選項。

## 後續可延伸的功能
- 週/月報表 PDF 匯出與分享。
- 智慧建議：依地點、時間或行事曆事件預填分類與標題。
- 獨立 widget / Live Activity，快速開始或停止計時。
- 後端（可選）：若需跨帳號同步與團隊報表，可建置輕量 API（Supabase/Firebase/CloudKit）來儲存條目，再與 Google Calendar 雙向同步。
