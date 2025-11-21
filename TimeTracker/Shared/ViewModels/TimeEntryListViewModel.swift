import Foundation
import SwiftData

@MainActor
final class TimeEntryListViewModel: ObservableObject {
    @Published var entries: [TimeEntry] = []
    @Published var selectedCategory: Category?
    @Published var searchText: String = "" {
        didSet { loadEntries() }
    }

    private let modelContext: ModelContext
    private let syncCoordinator: SyncCoordinator

    init(modelContext: ModelContext, syncCoordinator: SyncCoordinator) {
        self.modelContext = modelContext
        self.syncCoordinator = syncCoordinator
        loadEntries()
    }

    func loadEntries() {
        var predicates: [Predicate<TimeEntry>] = []
        if let selectedCategory {
            predicates.append(#Predicate { $0.category?.id == selectedCategory.id })
        }
        if !searchText.isEmpty {
            let term = searchText.lowercased()
            predicates.append(#Predicate { $0.title.lowercased().contains(term) || $0.notes.lowercased().contains(term) })
        }

        let predicate: Predicate<TimeEntry>? = if predicates.isEmpty { nil } else { predicates.reduce(Predicate<TimeEntry>.true) { $0 && $1 } }
        let descriptor = FetchDescriptor<TimeEntry>(predicate: predicate, sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        do {
            entries = try modelContext.fetch(descriptor)
        } catch {
            entries = []
        }
    }

    func deleteEntries(at offsets: IndexSet) {
        offsets
            .compactMap { entries[safe: $0] }
            .forEach { entry in
                modelContext.delete(entry)
                syncCoordinator.enqueue(action: .delete, for: entry)
            }
        try? modelContext.save()
        loadEntries()
    }

    func addOrUpdate(_ entry: TimeEntry) {
        entry.lastModified = Date()
        if modelContext.insertedObjects.contains(where: { ($0 as? TimeEntry)?.id == entry.id }) == false {
            modelContext.insert(entry)
        }
        syncCoordinator.enqueue(action: entry.calendarEventId == nil ? .insert : .update, for: entry)
        try? modelContext.save()
        loadEntries()
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
