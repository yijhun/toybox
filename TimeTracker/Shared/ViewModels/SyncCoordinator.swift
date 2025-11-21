import Foundation
import SwiftData

@MainActor
final class SyncCoordinator: ObservableObject {
    @Published var isSyncing = false
    @Published var lastError: Error?

    private let modelContext: ModelContext
    private let calendarManager: GoogleCalendarManager

    init(modelContext: ModelContext, calendarManager: GoogleCalendarManager) {
        self.modelContext = modelContext
        self.calendarManager = calendarManager
    }

    func enqueue(action: SyncAction, for entry: TimeEntry) {
        guard let payload = try? JSONEncoder().encode(entry) else { return }
        let task = PendingSyncTask(entryID: entry.id, action: action, payload: payload)
        modelContext.insert(task)
        try? modelContext.save()
    }

    func replayPendingQueue() async {
        if isSyncing { return }
        isSyncing = true
        defer { isSyncing = false }

        let descriptor = FetchDescriptor<PendingSyncTask>(sortBy: [SortDescriptor(\.createdAt)])
        guard let tasks = try? modelContext.fetch(descriptor) else { return }

        for task in tasks {
            do {
                let entry = try decodeEntry(from: task.payload)
                switch task.action {
                case .insert:
                    _ = try await calendarManager.insert(eventFor: entry)
                case .update:
                    try await calendarManager.update(eventFor: entry)
                case .delete:
                    try await calendarManager.delete(eventFor: entry)
                }
                modelContext.delete(task)
                try modelContext.save()
            } catch {
                lastError = error
                break
            }
        }
        calendarManager.lastSyncDate = Date()
    }

    private func decodeEntry(from data: Data) throws -> TimeEntry {
        let entry = try JSONDecoder().decode(TimeEntry.self, from: data)
        let descriptor = FetchDescriptor<TimeEntry>(predicate: #Predicate { $0.id == entry.id })
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        modelContext.insert(entry)
        try modelContext.save()
        return entry
    }
}
