import SwiftUI
import SwiftData

struct TimerPanelView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var syncCoordinator: SyncCoordinator
    @StateObject private var timerManager: TimerManager

    init(modelContext: ModelContext, calendarManager: GoogleCalendarManager) {
        let syncCoordinator = SyncCoordinator(modelContext: modelContext, calendarManager: calendarManager)
        _syncCoordinator = StateObject(wrappedValue: syncCoordinator)
        _timerManager = StateObject(wrappedValue: TimerManager(modelContext: modelContext, syncCoordinator: syncCoordinator))
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(timerManager.activeEntry?.title ?? "Start a timer")
                .font(.headline)
            Text(timerManager.elapsed.formatted(.units(style: .abbreviated)))
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .monospacedDigit()
            HStack {
                if timerManager.isRunning {
                    Button("Pause", action: timerManager.pauseTimer)
                    Button("Stop", role: .destructive, action: timerManager.stopTimer)
                } else {
                    Button("Resume", action: timerManager.resumeTimer)
                    Button("Start") {
                        timerManager.startTimer(title: "New Task")
                    }
                }
            }
        }
        .padding()
        .task {
            await syncCoordinator.replayPendingQueue()
        }
    }
}
