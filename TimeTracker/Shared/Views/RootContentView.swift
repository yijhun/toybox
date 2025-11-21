import SwiftUI
import SwiftData

struct RootContentView: View {
    @Environment(\.modelContext) private var modelContext
    private let syncCoordinator: SyncCoordinator
    private let calendarManager: GoogleCalendarManager

    init(modelContext: ModelContext) {
        let calendarManager = GoogleCalendarManager(modelContext: modelContext)
        self.calendarManager = calendarManager
        self.syncCoordinator = SyncCoordinator(modelContext: modelContext, calendarManager: calendarManager)
    }

    var body: some View {
        TabView {
            NavigationStack {
                TimerPanelView(modelContext: modelContext, calendarManager: calendarManager)
            }
            .tabItem { Label("Timer", systemImage: "timer") }

            NavigationStack {
                TimeEntryListView(viewModel: TimeEntryListViewModel(modelContext: modelContext, syncCoordinator: syncCoordinator))
            }
            .tabItem { Label("Entries", systemImage: "list.bullet") }

            NavigationStack {
                StatisticsView(viewModel: StatisticsViewModel(modelContext: modelContext))
            }
            .tabItem { Label("Stats", systemImage: "chart.bar") }

            NavigationStack {
                SettingsView(calendarManager: calendarManager) {
                    Task { await syncCoordinator.replayPendingQueue() }
                }
            }
            .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
