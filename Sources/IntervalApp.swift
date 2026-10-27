import SwiftUI

@main
struct IntervalApp: App {
    @StateObject private var store = WorkoutStore()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.light)
                .tint(Theme.blue)
        }
    }
}
