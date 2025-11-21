import Foundation
import SwiftData

@MainActor
enum PersistenceController {
    static var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TimeEntry.self,
            Category.self,
            PendingSyncTask.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}
