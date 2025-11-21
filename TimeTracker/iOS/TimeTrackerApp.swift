import SwiftUI
import SwiftData

@main
struct TimeTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootContentView(modelContext: PersistenceController.sharedModelContainer.mainContext)
        }
        .modelContainer(PersistenceController.sharedModelContainer)
    }
}
