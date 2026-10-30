import SwiftUI

@main
struct IntervalApp: App {
    @StateObject private var store = WorkoutStore()
    @ViewBuilder private var root: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--session-ui-test") {
            SessionScreen(workout: Workout(name: "Sporten", prepare: 0, work: 60, rest: 30, rounds: 3),
                          cue: .off, countdownSeconds: 3, haptics: false, awake: false,
                          skipDelay: true)
        } else { ContentView() }
        #else
        ContentView()
        #endif
    }
    var body: some Scene {
        WindowGroup {
            root
                .environmentObject(store)
                .preferredColorScheme(store.appearance.colorScheme)
                .tint(Theme.blue)
        }
    }
}
