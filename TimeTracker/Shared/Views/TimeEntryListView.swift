import SwiftUI
import SwiftData

struct TimeEntryListView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: TimeEntryListViewModel

    var body: some View {
        List {
            ForEach(viewModel.entries) { entry in
                NavigationLink(destination: TimeEntryDetailView(entry: entry)) {
                    VStack(alignment: .leading) {
                        Text(entry.title)
                            .font(.headline)
                        Text(entry.duration, format: .units(style: .abbreviated))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: viewModel.deleteEntries)
        }
        .searchable(text: $viewModel.searchText)
        .navigationTitle("Entries")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: addEntry) {
                    Label("Add", systemImage: "plus")
                }
            }
        }
    }

    private func addEntry() {
        let entry = TimeEntry(title: "New Entry")
        viewModel.addOrUpdate(entry)
    }
}

private struct TimeEntryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State var entry: TimeEntry

    var body: some View {
        Form {
            TextField("Title", text: $entry.title)
            TextField("Notes", text: $entry.notes, axis: .vertical)
            DatePicker("Start", selection: $entry.startDate)
            DatePicker("End", selection: Binding($entry.endDate, replacingNilWith: Date()))
        }
        .navigationTitle("Edit Entry")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
    }
}

private extension Binding where Value == Date? {
    init(_ source: Binding<Date?>, replacingNilWith fallback: Date) {
        self.init(get: { source.wrappedValue ?? fallback }, set: { source.wrappedValue = $0 })
    }
}
