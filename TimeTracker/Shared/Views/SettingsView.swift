import SwiftUI

struct SettingsView: View {
    @AppStorage("preferredCalendarId") private var preferredCalendarId: String = "primary"
    @ObservedObject var calendarManager: GoogleCalendarManager
    let onSyncNow: () -> Void

    var body: some View {
        Form {
            Section("Calendar") {
                TextField("Calendar ID", text: $preferredCalendarId)
                Button("Sync Now", action: onSyncNow)
                if let lastSyncDate = calendarManager.lastSyncDate {
                    Text("Last sync: \(lastSyncDate.formatted())")
                }
            }

            #if os(macOS)
            Section("Appearance") {
                Toggle("Show menu bar timer", isOn: .constant(true))
                    .disabled(true)
            }
            #endif

            #if os(watchOS)
            Section("Complications") {
                Text("Complications update alongside the sync queue.")
                    .font(.footnote)
            }
            #endif
        }
        .navigationTitle("Settings")
    }
}
