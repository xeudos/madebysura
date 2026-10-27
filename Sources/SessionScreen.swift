import SwiftUI

struct SessionScreen: View {
    @EnvironmentObject private var store: WorkoutStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var session: WorkoutSession
    @State private var confirmEnd = false

    init(workout: Workout, cue: CueMode, countdownSeconds: Int, haptics: Bool, awake: Bool) {
        _session = StateObject(wrappedValue: WorkoutSession(workout: workout, cue: cue, countdownSeconds: countdownSeconds, haptics: haptics, awake: awake))
    }
    private var color: Color { session.finished ? Theme.lime : Theme.color(session.phase?.kind ?? .prepare) }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 22) {
                    HStack {
                        Text(session.workout.name.isEmpty ? "My intervals" : session.workout.name)
                            .font(.subheadline.weight(.semibold)).lineLimit(1)
                        Spacer()
                        Button {
                            if session.finished { close() }
                            else { confirmEnd = true }
                        } label: {
                            Image(systemName: "xmark").font(.subheadline.bold())
                                .foregroundStyle(Theme.cream).padding(14)
                                .background(Theme.surface, in: Circle())
                        }.accessibilityLabel("End workout").disabled(session.preparing)
                    }

                    Spacer(minLength: 5)
                    if session.preparing {
                        SwiftUI.ProgressView().tint(Theme.lime).scaleEffect(1.5).padding(40)
                        Text("Getting your session ready…").foregroundStyle(.secondary)
                    } else if session.finished {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 72)).foregroundStyle(Theme.lime).padding(.top, 30)
                        Text("You showed up.")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                        Text("That's progress.").font(.title3).foregroundStyle(.secondary)
                        HStack(spacing: 45) {
                            metric(clockText(Int(session.actualSeconds.rounded())), label: "TIME TRAINED")
                            metric("\(session.workout.rounds * session.workout.sets)", label: "INTERVALS")
                        }.padding(.top, 22)
                    } else {
                        HStack(spacing: 35) {
                            metric("\(max(1, session.phase?.round ?? 1)) / \(session.workout.rounds)", label: "ROUND")
                            metric("\(max(1, session.phase?.set ?? 1)) / \(session.workout.sets)", label: "SET")
                        }
                        .padding(.top, 5)

                        ZStack {
                            Circle().stroke(color.opacity(0.12), lineWidth: 10)
                            Circle().trim(from: 0, to: max(0, 1 - session.snapshot.phaseProgress))
                                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            VStack(spacing: 12) {
                                Text(session.phase?.kind.title.uppercased() ?? "")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .tracking(3).foregroundStyle(color)
                                Text(clockText(session.snapshot.remaining))
                                    .font(.system(size: 79, weight: .medium, design: .rounded))
                                    .monospacedDigit().tracking(-4)
                                    .minimumScaleFactor(0.5).lineLimit(1)
                                if !session.running {
                                    Text("PAUSED").font(.caption.bold()).tracking(2).foregroundStyle(.secondary)
                                } else {
                                    Text(session.phase?.name ?? "").font(.subheadline)
                                        .foregroundStyle(.secondary).lineLimit(2)
                                }
                            }.padding(30)
                        }
                        .frame(maxWidth: 370)
                        .aspectRatio(1, contentMode: .fit)
                        .padding(.vertical, 6)
                        .accessibilityElement(children: .combine)

                        VStack(spacing: 10) {
                            HStack {
                                Text("SESSION REMAINING").font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .tracking(1)
                                Spacer()
                                Text(clockText(session.snapshot.totalRemaining)).monospacedDigit().font(.subheadline)
                            }.foregroundStyle(.secondary)
                            SwiftUI.ProgressView(value: session.snapshot.progress)
                                .tint(color).background(color.opacity(0.1))
                        }
                        if let next = session.nextPhase {
                            HStack {
                                SmallLabel(title: "Up next")
                                Spacer()
                                Text(next.name).font(.subheadline.weight(.medium)).lineLimit(1)
                                Text(clockText(next.duration)).font(.subheadline).foregroundStyle(.secondary)
                            }.padding(18).background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
                        }
                    }
                    Spacer(minLength: 10)

                    if session.finished {
                        BigButton(title: "Finish & save", icon: "checkmark") { close() }
                    } else if !session.preparing {
                        HStack(spacing: 14) {
                            BigButton(title: session.running ? "Pause" : "Resume",
                                      icon: session.running ? "pause.fill" : "play.fill", color: color) { session.toggle() }
                            Button { session.skip() } label: {
                                Image(systemName: "forward.end.fill").font(.title3)
                                    .foregroundStyle(color).frame(width: 66, height: 66)
                                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24))
                            }.accessibilityLabel("Skip interval")
                        }
                    }
                }
                .padding(.horizontal, 25).padding(.top, 12).padding(.bottom, 25)
                .frame(minHeight: geometry.size.height)
                .frame(maxWidth: 620).frame(maxWidth: .infinity)
            }
        }
        .background(Theme.background)
        .interactiveDismissDisabled()
        .task { await session.start() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { session.refresh() } }
        .confirmationDialog("End this workout?", isPresented: $confirmEnd, titleVisibility: .visible) {
            Button("End & save progress", role: .destructive) { close() }
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
            Text(value).font(.system(size: 23, weight: .semibold, design: .rounded)).monospacedDigit()
            SmallLabel(title: label)
        }
    }
    private func close() {
        session.end(store: store)
        dismiss()
    }
}
