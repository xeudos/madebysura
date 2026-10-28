import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: WorkoutStore
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Appearance", selection: $store.appearance) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }.pickerStyle(.segmented).padding(.vertical, 7)
                } header: { Text("Appearance") }
                    .listRowBackground(Theme.surface)

                Section {
                    Picker("Audio guidance", selection: $store.cue) {
                        ForEach(CueMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented).padding(.vertical, 7)
                } header: { Text("Sound") } footer: {
                    Text(store.cue == .off
                         ? "Silent mode. Keep the app open to see your cues."
                         : "Cues play with the screen locked and mix with your music. Calls pause the timer.")
                }.listRowBackground(Theme.surface)

                Section {
                    Picker("Countdown warning", selection: $store.countdownSeconds) {
                        Text("Off").tag(0)
                        ForEach(1...10, id: \.self) { Text("\($0) seconds").tag($0) }
                    }
                } footer: {
                    Text("When the warning begins before the next interval. Each favorite remembers its own setting.")
                }.listRowBackground(Theme.surface)

                Section {
                    Toggle("Haptic countdown", isOn: $store.haptics)
                    Toggle("Keep screen awake", isOn: $store.keepAwake)
                } header: { Text("During your workout") } footer: {
                    Text("Haptics work while the app is open. You can still lock the screen manually.")
                }.listRowBackground(Theme.surface)

                Section {
                    HStack(spacing: 13) {
                        Image(systemName: "timer").font(.system(size: 24, weight: .light))
                            .foregroundStyle(Theme.lime).frame(width: 44, height: 44)
                            .background(Theme.lime.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Interval").font(.system(size: 17, weight: .semibold))
                            Text("Made by Sura · 1.1").font(.caption).foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 6)
                } footer: { Text("Your favorites stay on this device. No account, ads, or subscriptions.") }
                    .listRowBackground(Theme.surface)
            }
            .tint(Theme.lime)
            .scrollContentBackground(.hidden).background(Theme.background)
            .navigationTitle("Settings")
        }
    }
}
