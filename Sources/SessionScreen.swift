import SwiftUI

struct SessionScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var session: WorkoutSession
    @State private var confirmEnd = false

    init(workout: Workout, cue: CueMode, countdownSeconds: Int, haptics: Bool, awake: Bool, liveActivities: Bool = true, skipDelay: Bool = true) {
        _session = StateObject(wrappedValue: WorkoutSession(workout: workout, cue: cue,
            countdownSeconds: countdownSeconds, haptics: haptics, awake: awake, liveActivities: liveActivities, skipDelay: skipDelay))
    }
    private var color: Color { session.finished ? Theme.lime : Theme.color(session.skipCountdown != nil ? .prepare : (session.phase?.kind ?? .prepare)) }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
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
                                .frame(width: 38, height: 38).background(Theme.elevated, in: Circle())
                        }.buttonStyle(.plain).accessibilityLabel("End workout").disabled(session.preparing)
                    }

                    Spacer(minLength: 5)
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
                            .font(.system(size: 106, weight: .medium, design: .rounded))
                            .tracking(-5).monospacedDigit().minimumScaleFactor(0.35).lineLimit(1)
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                            .accessibilityLabel("\(session.snapshot.remaining) seconds remaining")

                        Text(session.skipCountdown != nil ? "Next interval" : session.running
                             ? (session.phase?.name == session.phase?.kind.title ? " " : (session.phase?.name ?? " "))
                             : "Paused")
                            .font(.system(size: 19, weight: .medium)).foregroundStyle(.secondary).lineLimit(2)

                        HStack(spacing: 12) {
                            metric("\(max(1, session.phase?.round ?? 1)) / \(session.workout.rounds)", label: "Round")
                            metric("\(max(1, session.phase?.set ?? 1)) / \(session.workout.sets)", label: "Set")
                        }.padding(.vertical, 6)

                        VStack(spacing: 12) {
                            HStack {
                                SmallLabel(title: "Remaining")
                                Spacer()
                                Text(clockText(session.snapshot.totalRemaining))
                                    .font(.system(size: 14, weight: .medium)).monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                            SwiftUI.ProgressView(value: session.snapshot.progress).tint(color)
                        }.padding(.top, 8)
                        if let next = session.nextPhase {
                            HStack(spacing: 14) {
                                SmallLabel(title: "Next")
                                Text(next.name).font(.system(size: 14, weight: .medium)).lineLimit(1)
                                Spacer()
                                Text(clockText(next.duration)).font(.system(size: 14, weight: .medium))
                                    .monospacedDigit().foregroundStyle(.secondary)
                            }.padding(18).panel(radius: 18)
                        }
                    }
                    Spacer(minLength: 10)
                    if session.finished {
                        BigButton(title: "Done", icon: "checkmark") { close() }
                    } else if !session.preparing {
                        Button { session.restartInterval() } label: {
                            Label("Restart interval", systemImage: "arrow.counterclockwise")
                                .font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
                        }.buttonStyle(.plain).disabled(session.skipCountdown != nil)
                        HStack(spacing: 12) {
                            BigButton(title: session.skipCountdown != nil ? "Skip now" : (session.running ? "Pause" : "Resume"),
                                      icon: session.running ? "pause.fill" : "play.fill", color: color) { if session.skipCountdown != nil { session.requestSkip() } else { session.toggle() } }
                            Button { session.requestSkip() } label: {
                                Image(systemName: "forward.end.fill").font(.system(size: 18, weight: .medium))
                                    .frame(width: 60, height: 60).background(Theme.elevated, in: RoundedRectangle(cornerRadius: 20))
                            }.buttonStyle(.plain).accessibilityLabel("Skip interval")
                        }
                    }
                }
                .padding(.horizontal, 24).padding(.top, 15).padding(.bottom, 24)
                .frame(minHeight: geometry.size.height)
                .frame(maxWidth: 620).frame(maxWidth: .infinity)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .interactiveDismissDisabled()
        .task { await session.start() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { session.refresh() } }
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
    private func metric(_ value: String, label: String) -> some View {
        VStack(spacing: 7) {
            SmallLabel(title: label)
            Text(value).font(.system(size: 24, weight: .medium, design: .rounded)).monospacedDigit()
        }.frame(maxWidth: .infinity).padding(.vertical, 18).panel(radius: 20)
    }
    private func close() {
        session.end()
        dismiss()
    }
}
