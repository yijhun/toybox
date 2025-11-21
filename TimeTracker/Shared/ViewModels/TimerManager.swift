import Foundation
import SwiftData

@MainActor
final class TimerManager: ObservableObject {
    @Published var activeEntry: TimeEntry?
    @Published var elapsed: TimeInterval = 0
    @Published var isRunning: Bool = false

    private var timerTask: Task<Void, Never>?
    private var modelContext: ModelContext
    private let syncCoordinator: SyncCoordinator

    init(modelContext: ModelContext, syncCoordinator: SyncCoordinator) {
        self.modelContext = modelContext
        self.syncCoordinator = syncCoordinator
        restoreActiveEntry()
    }

    func startTimer(title: String, notes: String = "", category: Category? = nil) {
        guard activeEntry == nil else { return }
        let entry = TimeEntry(title: title, notes: notes, category: category)
        modelContext.insert(entry)
        save()
        startTicking(with: entry)
    }

    func stopTimer() {
        guard let entry = activeEntry else { return }
        entry.endDate = Date()
        entry.lastModified = Date()
        save()
        syncCoordinator.enqueue(action: entry.calendarEventId == nil ? .insert : .update, for: entry)
        cancelTimer()
    }

    func pauseTimer() {
        isRunning = false
        cancelTimer()
    }

    func resumeTimer() {
        guard let entry = activeEntry, !isRunning else { return }
        startTicking(with: entry)
    }

    private func restoreActiveEntry() {
        let descriptor = FetchDescriptor<TimeEntry>(predicate: #Predicate { $0.endDate == nil })
        if let entry = try? modelContext.fetch(descriptor).first {
            startTicking(with: entry)
        }
    }

    private func startTicking(with entry: TimeEntry) {
        activeEntry = entry
        elapsed = entry.duration
        isRunning = true
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !(Task.isCancelled) {
                try? await Task.sleep(for: .seconds(1))
                await MainActor.run {
                    guard let self else { return }
                    self.elapsed = entry.duration
                }
            }
        }
    }

    private func cancelTimer() {
        timerTask?.cancel()
        timerTask = nil
        activeEntry = nil
        isRunning = false
    }

    private func save() {
        try? modelContext.save()
    }
}
