import SwiftUI

struct SessionScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var session: WorkoutSession
    @State private var confirmEnd = false
    @State private var showBackgroundDetails = false

    init(workout: Workout, cue: CueMode, countdownSeconds: Int, haptics: Bool, awake: Bool, liveActivities: Bool = true, skipDelay: Bool = true, notifications: Bool = false) {
        _session = StateObject(wrappedValue: WorkoutSession(workout: workout, cue: cue,
            countdownSeconds: countdownSeconds, haptics: haptics, awake: awake, liveActivities: liveActivities, skipDelay: skipDelay, notifications: notifications))
    }
    private var color: Color { session.finished ? Theme.lime : Theme.color(session.skipCountdown != nil ? .prepare : (session.phase?.kind ?? .prepare)) }
    private var hasBackgroundIssue: Bool { session.liveNeedsAttention || session.notificationStatus != nil }
    private var subtitle: String? {
        if session.skipCountdown != nil { return "Next interval" }
        if !session.running { return "Paused" }
        guard let phase = session.phase, phase.name != phase.kind.title else { return nil }
        return phase.name
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: geometry.size.height < 650 ? 16 : 24) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            SmallLabel(title: "Your session")
                            Text(session.workout.name.isEmpty ? "My intervals" : session.workout.name)
                                .font(.system(size: 16, weight: .semibold)).lineLimit(1)
                        }
                        Spacer()
                        Button {
                            if session.finished { close() } else { confirmEnd = true }
                        } label: {
                            Image(systemName: "xmark").font(.system(size: 13, weight: .semibold))
                                .frame(width: 44, height: 44).background(Theme.elevated, in: Circle())
                        }.buttonStyle(.plain).accessibilityLabel("End workout").disabled(session.preparing)
                    }
                    Spacer(minLength: 0)
                    if session.preparing {
                        SwiftUI.ProgressView().tint(Theme.lime).scaleEffect(1.4).padding(40)
                        Text("Preparing your timer…").font(.subheadline).foregroundStyle(.secondary)
                    } else if session.finished {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 76, weight: .ultraLight)).foregroundStyle(Theme.lime)
                        Text("Session complete").font(.system(size: 30, weight: .semibold, design: .rounded))
                        Text(clockText(Int(session.actualSeconds.rounded())))
                            .font(.system(size: 68, weight: .medium, design: .rounded)).monospacedDigit()
                        Text("Time trained").font(.subheadline).foregroundStyle(.secondary)
                    } else {
                        Text(session.skipCountdown != nil ? "GET READY" : (session.phase?.kind.title.uppercased() ?? ""))
                            .font(.system(size: 12, weight: .semibold)).tracking(2)
                            .foregroundStyle(color).padding(.horizontal, 17).padding(.vertical, 10)
                            .background(color.opacity(0.1), in: Capsule())
                        Text(clockText(session.skipCountdown ?? session.snapshot.remaining))
                            .font(.system(size: geometry.size.height < 600 ? 88 : 106, weight: .medium, design: .rounded))
                            .tracking(-5).monospacedDigit().minimumScaleFactor(0.35).lineLimit(1)
                            .frame(maxWidth: .infinity).padding(.vertical, 4)
                            .accessibilityLabel("\(session.skipCountdown ?? session.snapshot.remaining) seconds remaining")
                        if let subtitle {
                            Text(subtitle).font(.system(size: 19, weight: .medium))
                                .foregroundStyle(.secondary).lineLimit(2)
                        }
                        HStack(spacing: 12) {
                            metric("\(max(1, session.phase?.round ?? 1)) / \(session.workout.rounds)", label: "Round")
                            metric("\(max(1, session.phase?.set ?? 1)) / \(session.workout.sets)", label: "Set")
                        }
                        VStack(spacing: 12) {
                            HStack {
                                SmallLabel(title: "Remaining")
                                Spacer()
                                Text(clockText(session.snapshot.totalRemaining))
                                    .font(.system(size: 14, weight: .medium)).monospacedDigit().foregroundStyle(.secondary)
                            }
                            SwiftUI.ProgressView(value: session.snapshot.progress).tint(color)
                        }
                        if let next = session.nextPhase {
                            HStack(spacing: 14) {
                                SmallLabel(title: "Next")
                                Text(next.name).font(.system(size: 14, weight: .medium)).lineLimit(1)
                                Spacer()
                                Text(clockText(next.duration)).font(.system(size: 14, weight: .medium))
                                    .monospacedDigit().foregroundStyle(.secondary)
                            }.padding(18).panel(radius: 18)
                        }
                        Button { showBackgroundDetails = true } label: {
                            Label(hasBackgroundIssue ? "Background features need setup" : "Background features",
                                  systemImage: hasBackgroundIssue ? "info.circle" : "wave.3.right")
                                .font(.caption).foregroundStyle(.secondary).frame(minHeight: 44)
                        }.buttonStyle(.plain).accessibilityIdentifier("session.backgroundDetails")
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24).padding(.top, 15).padding(.bottom, 12)
                .frame(minHeight: geometry.size.height)
                .frame(maxWidth: 620).frame(maxWidth: .infinity)
            }
        }
        // Controls live outside the scroll content, so text, errors and display size cannot push them off screen.
        .safeAreaInset(edge: .bottom, spacing: 0) { controls }
        .background(Theme.background.ignoresSafeArea())
        .interactiveDismissDisabled()
        .task { await session.start() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { session.refresh() } }
        .sheet(isPresented: $showBackgroundDetails) { backgroundDetails }
        .confirmationDialog("End this workout?", isPresented: $confirmEnd, titleVisibility: .visible) {
            Button("End workout", role: .destructive) { close() }
            Button("Keep going", role: .cancel) {}
        }
        .alert("Audio unavailable", isPresented: Binding(
            get: { session.error != nil }, set: { if !$0 { session.error = nil } }
        )) {
            Button("Continue") { session.error = nil }
        } message: { Text(session.error ?? "") }
    }
    private var controls: some View {
        VStack(spacing: 10) {
            if session.finished {
                BigButton(title: "Done", icon: "checkmark") { close() }
            } else if !session.preparing {
                Button { session.restartInterval() } label: {
                    Label("Restart interval", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary).frame(minHeight: 32)
                }.buttonStyle(.plain).disabled(session.skipCountdown != nil).accessibilityIdentifier("session.restart")
                HStack(spacing: 12) {
                    BigButton(title: session.skipCountdown != nil ? "Skip now" : (session.running ? "Pause" : "Resume"),
                              icon: session.skipCountdown != nil ? "forward.end.fill" : (session.running ? "pause.fill" : "play.fill"), color: color) {
                        if session.skipCountdown != nil { session.requestSkip() } else { session.toggle() }
                    }.accessibilityIdentifier("session.primary")
                    Button { session.requestSkip() } label: {
                        Label("Skip", systemImage: "forward.end.fill")
                            .font(.system(size: 16, weight: .semibold)).minimumScaleFactor(0.7).lineLimit(1)
                            .frame(width: 106, height: 60).background(Theme.elevated, in: RoundedRectangle(cornerRadius: 20))
                    }.buttonStyle(.plain)
                        .accessibilityLabel(session.skipCountdown != nil ? "Skip immediately" : "Skip interval")
                        .accessibilityHint("Tap once for a 3-second countdown. Tap again to skip immediately.")
                        .accessibilityIdentifier("session.skip")
                }
            }
        }
        .frame(maxWidth: 620).frame(maxWidth: .infinity)
        .padding(.horizontal, 24).padding(.top, 8).padding(.bottom, 12)
        .background(Theme.background)
        .overlay(alignment: .top) { Theme.border.opacity(0.5).frame(height: 0.5) }
    }
    private var backgroundDetails: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if RuntimeEnvironment.isLiveContainer {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Running in LiveContainer").font(.headline)
                            Text("Live Activities need a widget extension, which LiveContainer cannot register for this app. Install Interval as a separate app to use the Lock Screen timer and Dynamic Island.")
                        }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Live Activity").font(.headline)
                        Text(session.liveStatus).foregroundStyle(.secondary)
                        if !RuntimeEnvironment.isLiveContainer && session.liveNeedsAttention {
                            Button("Retry Live Activity") { session.retryLiveActivity() }
                        }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Interval notifications").font(.headline)
                        Text(session.notificationStatus ?? "Notifications follow your preferences and iOS permissions.")
                            .foregroundStyle(.secondary)
                        if RuntimeEnvironment.isLiveContainer {
                            Text("In LiveContainer, open Interval’s app settings and enable Fix Local Notifications, then relaunch Interval. Also allow notifications for LiveContainer in iPhone Settings.")
                        }
                        Button("Check notification permission") { Task { await session.retryNotifications() } }
                    }
                    Button("Open iPhone Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    }
                }.font(.subheadline).padding(24)
            }.background(Theme.background)
                .navigationTitle("Background features").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showBackgroundDetails = false }.accessibilityIdentifier("diagnostics.done")
                } }
        }.tint(Theme.lime).presentationDetents([.medium, .large])
    }
    private func metric(_ value: String, label: String) -> some View {
        VStack(spacing: 7) {
            SmallLabel(title: label)
            Text(value).font(.system(size: 24, weight: .medium, design: .rounded)).monospacedDigit()
        }.frame(maxWidth: .infinity).padding(.vertical, 14).panel(radius: 20)
    }
    private func close() {
        session.end()
        dismiss()
    }
}
