import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: WorkoutStore
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Audio guidance", selection: $store.cue) {
                        ForEach(CueMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented).padding(.vertical, 5)
                } header: { Text("Your sound") } footer: {
                    Text(store.cue == .off
                         ? "Silent mode: keep the app open to see your cues. Elapsed time catches up when you return."
                         : "Audio cues continue with the screen locked and mix with your music. Phone calls pause the session. Voice guidance uses the English voice available on your iPhone.")
                }
                .listRowBackground(Theme.surface)
                Section {
                    Picker("Countdown starts", selection: $store.countdownSeconds) {
                        Text("Off").tag(0)
                        ForEach(1...10, id: \.self) { Text("\($0) seconds before").tag($0) }
                    }
                } header: { Text("Countdown warning") } footer: {
                    Text("Choose when the countdown beeps begin before the next interval. Set 3 or 5 seconds, or turn the warning off. Voice mode speaks the same countdown.")
                }.listRowBackground(Theme.surface)
                Section {
                    Toggle("Haptic countdown", isOn: $store.haptics)
                    Toggle("Keep screen awake", isOn: $store.keepAwake)
                } header: { Text("During your workout") } footer: {
                    Text("Haptics work while the app is open. Your screen can still be locked manually.")
                }.listRowBackground(Theme.surface)
                Section {
                    Label("No account needed", systemImage: "person.crop.circle.badge.checkmark")
                    Label("History stays on this device", systemImage: "iphone")
                    Label("No ads or subscriptions", systemImage: "heart")
                } header: { Text("Made for your routine") }
                    .listRowBackground(Theme.surface)
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interval").font(.system(size: 26, weight: .bold, design: .rounded))
                        Text("Made by Sura · 1.0").font(.subheadline).foregroundStyle(.secondary)
                        Text("A personal interval timer inspired by the simple workout timers we love.")
                            .font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 10)
                }.listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden).background(Theme.background)
            .navigationTitle("Make it yours")
        }
    }
}
