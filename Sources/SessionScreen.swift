import SwiftUI

struct SessionScreen: View {
    @EnvironmentObject private var store: WorkoutStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var session: WorkoutSession
    @State private var confirmEnd = false

    init(workout: Workout, cue: CueMode, countdownSeconds: Int, haptics: Bool, awake: Bool) {
        _session = StateObject(wrappedValue: WorkoutSession(workout: workout, cue: cue,
            countdownSeconds: countdownSeconds, haptics: haptics, awake: awake))
    }
    private var color: Color { session.finished ? Theme.lime : Theme.color(session.phase?.kind ?? .prepare) }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 22) {
                    HStack {
                        Text(session.workout.name.isEmpty ? "Interval Timer" : session.workout.name)
                            .font(.system(size: 18, weight: .medium)).lineLimit(1)
                        Spacer()
                        Button {
                            if session.finished { close() }
                            else { confirmEnd = true }
                        } label: {
                            Image(systemName: "xmark").font(.system(size: 20, weight: .light))
                                .frame(width: 42, height: 42)
                        }.accessibilityLabel("End workout").disabled(session.preparing)
                    }.padding(.bottom, 5)

                    Spacer(minLength: 5)
                    if session.preparing {
                        SwiftUI.ProgressView().tint(.white).scaleEffect(1.5).padding(40)
                        Text("Preparing timer…").opacity(0.8)
                    } else if session.finished {
                        Image(systemName: "checkmark.circle").font(.system(size: 85, weight: .ultraLight))
                        Text("COMPLETE").font(.system(size: 32, weight: .light)).tracking(3)
                        Text(clockText(Int(session.actualSeconds.rounded())))
                            .font(.system(size: 78, weight: .ultraLight)).monospacedDigit()
                        Text("Time trained").font(.subheadline).opacity(0.8)
                    } else {
                        Text(session.phase?.kind.title.uppercased() ?? "")
                            .font(.system(size: 32, weight: .light)).tracking(4)
                            .padding(.top, 12)
                        Text(clockText(session.snapshot.remaining))
                            .font(.system(size: 112, weight: .ultraLight))
                            .monospacedDigit().minimumScaleFactor(0.35).lineLimit(1)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .accessibilityLabel("\(session.snapshot.remaining) seconds remaining")
                        Text(session.phase?.name == session.phase?.kind.title ? " " : (session.phase?.name ?? " "))
                            .font(.system(size: 23, weight: .light)).lineLimit(2)
                        if !session.running {
                            Text("PAUSED").font(.system(size: 15, weight: .semibold)).tracking(3)
                        }
                        HStack(spacing: 55) {
                            metric("\(max(1, session.phase?.round ?? 1)) / \(session.workout.rounds)", label: "ROUND")
                            metric("\(max(1, session.phase?.set ?? 1)) / \(session.workout.sets)", label: "SET")
                        }.padding(.vertical, 10)

                        SwiftUI.ProgressView(value: session.snapshot.progress).tint(.white)
                            .background(Color.white.opacity(0.15))
                        HStack {
                            Text("TOTAL REMAINING").font(.system(size: 11, weight: .semibold))
                            Spacer()
                            Text(clockText(session.snapshot.totalRemaining)).monospacedDigit()
                        }.opacity(0.8)
                        if let next = session.nextPhase {
                            HStack {
                                Text("NEXT").font(.system(size: 11, weight: .semibold))
                                Spacer()
                                Text(next.name).lineLimit(1)
                                Text(clockText(next.duration)).monospacedDigit()
                            }.font(.system(size: 15))
                                .padding(16).background(Color.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    Spacer(minLength: 15)
                    if session.finished {
                        actionButton("DONE", icon: "checkmark") { close() }
                    } else if !session.preparing {
                        HStack(spacing: 14) {
                            actionButton(session.running ? "PAUSE" : "RESUME",
                                         icon: session.running ? "pause.fill" : "play.fill") { session.toggle() }
                            Button { session.skip() } label: {
                                Image(systemName: "forward.end").font(.system(size: 25, weight: .light))
                                    .frame(width: 65, height: 65)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.7), lineWidth: 1))
                            }.accessibilityLabel("Skip interval")
                        }
                    }
                }
                .padding(.horizontal, 25).padding(.top, 12).padding(.bottom, 25)
                .frame(minHeight: geometry.size.height)
                .frame(maxWidth: 620).frame(maxWidth: .infinity)
            }
        }
        .foregroundStyle(.white)
        .background(color.ignoresSafeArea())
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
    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                Text(title).font(.system(size: 20, weight: .medium))
            }
            .frame(maxWidth: .infinity).frame(height: 65)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.7), lineWidth: 1))
        }.buttonStyle(.plain)
    }
    private func metric(_ value: String, label: String) -> some View {
        VStack(spacing: 5) {
            Text(label).font(.system(size: 11, weight: .semibold)).opacity(0.8)
            Text(value).font(.system(size: 26, weight: .light)).monospacedDigit()
        }
    }
    private func close() {
        session.end(store: store)
        dismiss()
    }
}
