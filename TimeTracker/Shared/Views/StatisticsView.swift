import SwiftUI

struct StatisticsView: View {
    @ObservedObject var viewModel: StatisticsViewModel

    var body: some View {
        List {
            if !viewModel.dailySummaries.isEmpty {
                Section("By Day") {
                    ForEach(viewModel.dailySummaries) { summary in
                        HStack {
                            Text(summary.date, style: .date)
                            Spacer()
                            Text(summary.totalDuration, format: .units(style: .abbreviated))
                                .monospacedDigit()
                        }
                    }
                }
            }

            if !viewModel.totalsByCategory.isEmpty {
                Section("By Category") {
                    ForEach(Array(viewModel.totalsByCategory.enumerated()), id: \.offset) { _, item in
                        HStack {
                            Text(item.0.name)
                            Spacer()
                            Text(item.1, format: .units(style: .abbreviated))
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
        .navigationTitle("Statistics")
        .onAppear { viewModel.refresh() }
    }
}
