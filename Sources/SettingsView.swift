import SwiftUI
import ActivityKit

struct SettingsView: View {
    @EnvironmentObject private var store: WorkoutStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var notificationCheck = PhaseNotifications()
    @State private var sendingTest = false
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
                    Toggle("Lock Screen & Dynamic Island", isOn: $store.liveActivities)
                    if RuntimeEnvironment.isLiveContainer {
                        Text(RuntimeEnvironment.liveActivityLimitation).font(.footnote).foregroundStyle(.secondary)
                    } else {
                        LabeledContent("Widget extension", value: LiveActivityController.extensionInstalled ? "Installed" : "Missing")
                    }
                    LabeledContent("iPhone permission", value: ActivityAuthorizationInfo().areActivitiesEnabled ? "Allowed" : "Disabled")
                    Button("Open iPhone Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    }
                } header: { Text("Live Activity") } footer: {
                    Text("Shows the current interval while you train. Tap it to return to the timer. Start a workout, then go Home or lock your iPhone. Dynamic Island requires a compatible iPhone. When sideloading, include the widget extension.")
                }.listRowBackground(Theme.surface)
                Section {
                    Toggle("Interval notifications", isOn: $store.phaseNotifications)
                    LabeledContent("iPhone permission", value: notificationCheck.permissionSummary)
                    if !notificationCheck.deliverySummary.isEmpty {
                        Text(notificationCheck.deliverySummary).font(.footnote).foregroundStyle(.secondary)
                    }
                    Button {
                        sendingTest = true
                        Task {
                            await notificationCheck.sendTest()
                            sendingTest = false
                        }
                    } label: {
                        Label(sendingTest ? "Scheduling test…" : "Send test notification", systemImage: "bell.badge")
                    }.disabled(sendingTest)
                    if let message = notificationCheck.status {
                        Text(message).font(.footnote).foregroundStyle(.secondary)
                    }
                } footer: {
                    Text(RuntimeEnvironment.isLiveContainer ? RuntimeEnvironment.notificationSetup : "Allows notifications at interval changes and workout completion while the app is in the background. Permission is requested when you start a workout.")
                }.listRowBackground(Theme.surface)
                Section {
                    Toggle("3-second skip countdown", isOn: $store.skipDelay)
                } footer: {
                    Text("Tap Skip once for 3 seconds to get ready. Tap again during the countdown to skip immediately. Paused timers skip immediately.")
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
                            Text("Made by Sura · 1.2.3").font(.caption).foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 6)
                } footer: { Text("Your favorites stay on this device. No account, ads, or subscriptions.") }
                    .listRowBackground(Theme.surface)
            }
            .tint(Theme.lime)
            .scrollContentBackground(.hidden).background(Theme.background)
            .navigationTitle("Settings")
            .task { await notificationCheck.refreshPermission() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await notificationCheck.refreshPermission() } }
            }
        }
    }
}
