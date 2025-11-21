import SwiftUI

#if os(macOS)
struct MenuBarTimerView: View {
    @ObservedObject var timerManager: TimerManager

    var body: some View {
        VStack(spacing: 8) {
            Text(timerManager.activeEntry?.title ?? "Ready")
                .font(.headline)
            Text(timerManager.elapsed.formatted(.units(style: .abbreviated)))
                .monospacedDigit()
            HStack {
                if timerManager.isRunning {
                    Button("Pause", action: timerManager.pauseTimer)
                    Button("Stop", action: timerManager.stopTimer)
                } else {
                    Button("Start") { timerManager.startTimer(title: "Quick Task") }
                }
            }
        }
        .padding()
        .frame(width: 240)
    }
}
#endif
