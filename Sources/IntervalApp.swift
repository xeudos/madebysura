import SwiftUI

@main
struct IntervalApp: App {
    @StateObject private var store = WorkoutStore()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(store.appearance.colorScheme)
                .tint(Theme.blue)
                .task { await LiveActivityController.clearOrphans() }
        }
    }
}
