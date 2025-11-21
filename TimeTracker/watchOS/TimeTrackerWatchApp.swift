import SwiftUI
import SwiftData

@main
struct TimeTrackerWatchApp: App {
    @StateObject private var timerManager: TimerManager
    @StateObject private var syncCoordinator: SyncCoordinator
    @StateObject private var calendarManager: GoogleCalendarManager

    init() {
        let modelContext = PersistenceController.sharedModelContainer.mainContext
        let calendarManager = GoogleCalendarManager(modelContext: modelContext)
        let syncCoordinator = SyncCoordinator(modelContext: modelContext, calendarManager: calendarManager)
        _calendarManager = StateObject(wrappedValue: calendarManager)
        _syncCoordinator = StateObject(wrappedValue: syncCoordinator)
        _timerManager = StateObject(wrappedValue: TimerManager(modelContext: modelContext, syncCoordinator: syncCoordinator))
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                VStack(spacing: 12) {
                    Text(timerManager.activeEntry?.title ?? "Timer")
                        .font(.headline)
                    Text(timerManager.elapsed.formatted(.units(style: .abbreviated)))
                        .monospacedDigit()
                    HStack {
                        if timerManager.isRunning {
                            Button("Stop", action: timerManager.stopTimer)
                        } else {
                            Button("Start") { timerManager.startTimer(title: "Watch Task") }
                        }
                    }
                    NavigationLink("Entries") {
                        TimeEntryListView(viewModel: TimeEntryListViewModel(modelContext: PersistenceController.sharedModelContainer.mainContext, syncCoordinator: syncCoordinator))
                    }
                }
            }
            .modelContainer(PersistenceController.sharedModelContainer)
        }
    }
}
