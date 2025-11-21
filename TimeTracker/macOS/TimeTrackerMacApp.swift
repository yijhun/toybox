import SwiftUI
import SwiftData

@main
struct TimeTrackerMacApp: App {
    @StateObject private var calendarManager = GoogleCalendarManager(modelContext: PersistenceController.sharedModelContainer.mainContext)
    @StateObject private var syncCoordinator: SyncCoordinator
    @StateObject private var timerManager: TimerManager

    init() {
        let calendarManager = GoogleCalendarManager(modelContext: PersistenceController.sharedModelContainer.mainContext)
        let syncCoordinator = SyncCoordinator(modelContext: PersistenceController.sharedModelContainer.mainContext, calendarManager: calendarManager)
        _calendarManager = StateObject(wrappedValue: calendarManager)
        _syncCoordinator = StateObject(wrappedValue: syncCoordinator)
        _timerManager = StateObject(wrappedValue: TimerManager(modelContext: PersistenceController.sharedModelContainer.mainContext, syncCoordinator: syncCoordinator))
    }

    var body: some Scene {
        WindowGroup {
            RootContentView(modelContext: PersistenceController.sharedModelContainer.mainContext)
        }
        .modelContainer(PersistenceController.sharedModelContainer)

        MenuBarExtra("TimeTracker", systemImage: "timer") {
            MenuBarTimerView(timerManager: timerManager)
                .modelContainer(PersistenceController.sharedModelContainer)
        }
    }
}
