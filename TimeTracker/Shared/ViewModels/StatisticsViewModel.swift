import Foundation
import SwiftData

struct DailySummary: Identifiable {
    let id = UUID()
    let date: Date
    let totalDuration: TimeInterval
    let entries: [TimeEntry]
}

@MainActor
final class StatisticsViewModel: ObservableObject {
    @Published var dailySummaries: [DailySummary] = []
    @Published var totalsByCategory: [(Category, TimeInterval)] = []

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        refresh()
    }

    func refresh() {
        let descriptor = FetchDescriptor<TimeEntry>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        guard let entries = try? modelContext.fetch(descriptor) else {
            dailySummaries = []
            totalsByCategory = []
            return
        }

        let grouped = Dictionary(grouping: entries) { Calendar.current.startOfDay(for: $0.startDate) }
        dailySummaries = grouped.keys.sorted(by: >).map { day in
            let dayEntries = grouped[day] ?? []
            let total = dayEntries.reduce(0) { $0 + $1.duration }
            return DailySummary(date: day, totalDuration: total, entries: dayEntries)
        }

        let byCategory = Dictionary(grouping: entries) { $0.category }
        totalsByCategory = byCategory.compactMap { category, entries in
            guard let category else { return nil }
            let total = entries.reduce(0) { $0 + $1.duration }
            return (category, total)
        }.sorted { $0.1 > $1.1 }
    }
}
