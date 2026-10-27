import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: WorkoutStore
    @State private var tab = 0
    var body: some View {
        TabView(selection: $tab) {
            TimerHome().tabItem { Label("Timer", systemImage: "timer") }.tag(0)
            LibraryView(tab: $tab).tabItem { Label("Workouts", systemImage: "square.stack.3d.up") }.tag(1)
            ProgressView(tab: $tab).tabItem { Label("Progress", systemImage: "chart.bar.xaxis") }.tag(2)
            SettingsView().tabItem { Label("Settings", systemImage: "slider.horizontal.3") }.tag(3)
        }
        .toolbarBackground(Theme.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .alert("Storage unavailable", isPresented: Binding(
            get: { store.storageError != nil }, set: { if !$0 { store.storageError = nil } }
        )) {
            Button("OK") { store.storageError = nil }
        } message: { Text(store.storageError ?? "") }
    }
}

private enum IntervalField: String, Identifiable {
    case prepare, work, rest, recovery, cooldown
    var id: String { rawValue }
    var title: String {
        switch self {
        case .prepare: return "Warm up"
        case .work: return "Work"
        case .rest: return "Rest"
        case .recovery: return "Between sets"
        case .cooldown: return "Cool down"
        }
    }
    var color: Color {
        switch self {
        case .work: return Theme.lime
        case .rest: return Theme.blue
        case .recovery: return Theme.orange
        default: return Theme.cream
        }
    }
    var icon: String {
        switch self {
        case .prepare: return "sun.max"
        case .work: return "bolt.fill"
        case .rest: return "wind"
        case .recovery: return "arrow.triangle.2.circlepath"
        case .cooldown: return "moon"
        }
    }
}

struct TimerHome: View {
    @EnvironmentObject private var store: WorkoutStore
    @State private var editing: IntervalField?
    @State private var showExercises = false
    @State private var showSession = false
    @State private var showSaved = false

    private func value(_ field: IntervalField) -> Binding<Int> {
        Binding(get: {
            switch field {
            case .prepare: return store.draft.prepare
            case .work: return store.draft.work
            case .rest: return store.draft.rest
            case .recovery: return store.draft.recovery
            case .cooldown: return store.draft.cooldown
            }
        }, set: { newValue in
            switch field {
            case .prepare: store.draft.prepare = newValue
            case .work: store.draft.work = newValue
            case .rest: store.draft.rest = newValue
            case .recovery: store.draft.recovery = newValue
            case .cooldown: store.draft.cooldown = newValue
            }
        })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            SmallLabel(title: "YOUR PACE. YOUR SESSION.")
                            Text("Make time.\nMake progress.")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .tracking(-1.5)
                        }
                        Spacer(minLength: 2)
                        Image(systemName: "timer")
                            .font(.system(size: 25, weight: .medium))
                            .foregroundStyle(Theme.lime).padding(14)
                            .background(Theme.surface, in: Circle())
                    }
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            TextField("Workout name", text: $store.draft.name)
                                .font(.system(size: 18, weight: .semibold))
                                .accessibilityLabel("Workout name")
                            Button {
                                store.savePreset()
                                showSaved = true
                            } label: {
                                Image(systemName: showSaved ? "checkmark.circle.fill" : "bookmark")
                                    .font(.system(size: 20)).foregroundStyle(Theme.lime)
                            }
                            .accessibilityLabel("Save workout")
                            .disabled(store.draft.validationMessage != nil)
                        }
                        HStack(alignment: .lastTextBaseline, spacing: 7) {
                            Text(clockText(store.draft.totalDuration))
                                .font(.system(size: 48, weight: .medium, design: .rounded))
                                .monospacedDigit().tracking(-2)
                            Text("TOTAL").font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(.secondary)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 5) {
                                Text("\(store.draft.rounds * store.draft.sets)")
                                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                                SmallLabel(title: "intervals")
                            }
                        }
                    }
                    .padding(23).background(Theme.surface, in: RoundedRectangle(cornerRadius: 26))

                    VStack(spacing: 9) {
                        HStack {
                            SmallLabel(title: "Build your workout")
                            Spacer()
                            Text("Tap or drag a value").font(.caption2).foregroundStyle(.secondary)
                        }.padding(.bottom, 3)
                        intervalRow(.prepare)
                        intervalRow(.work)
                        intervalRow(.rest)
                        counterRow("Rounds", subtitle: "per set", icon: "repeat", value: $store.draft.rounds, range: 1...60)
                        counterRow("Sets", subtitle: "complete circuits", icon: "square.stack", value: $store.draft.sets, range: 1...20)
                        if store.draft.sets > 1 { intervalRow(.recovery) }
                        intervalRow(.cooldown)
                    }

                    Button { showExercises = true } label: {
                        HStack {
                            Label("Name your exercises", systemImage: "list.bullet")
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption.bold())
                        }.font(.subheadline.weight(.medium)).foregroundStyle(Theme.cream)
                    }

                    if let message = store.draft.validationMessage {
                        Text(message).font(.callout).foregroundStyle(Theme.orange)
                    }
                    BigButton(title: "Start workout") { showSession = true }
                        .disabled(store.draft.validationMessage != nil)
                        .opacity(store.draft.validationMessage == nil ? 1 : 0.4)
                    HStack {
                        Image(systemName: store.cue == .off ? "speaker.slash" : "waveform")
                        Text(store.cue == .off ? "Silent session" : "\(store.cue.rawValue) cues · \(store.countdownSeconds)s countdown")
                    }
                    .font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 22).padding(.top, 20).padding(.bottom, 25)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.background)
            .navigationTitle("Interval").navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editing) { field in
                DurationEditor(title: field.title, value: value(field), minimum: field == .work ? 1 : 0)
                    .presentationDetents([.height(350)])
            }
            .sheet(isPresented: $showExercises) { ExerciseEditor() }
            .fullScreenCover(isPresented: $showSession) {
                SessionScreen(workout: store.draft, cue: store.cue, countdownSeconds: store.countdownSeconds, haptics: store.haptics, awake: store.keepAwake)
            }
            .alert("Workout saved", isPresented: $showSaved) {
                Button("Done", role: .cancel) {}
            } message: { Text("Find it in your favorite timers in the Workouts tab.") }
        }
    }

    private func intervalRow(_ field: IntervalField) -> some View {
        let binding = value(field)
        return Button { editing = field } label: {
            HStack(spacing: 13) {
                Image(systemName: field.icon).font(.system(size: 19, weight: .medium))
                    .frame(width: 27).foregroundStyle(field.color)
                Text(field.title).font(.system(size: 17, weight: .semibold, design: .rounded))
                Spacer()
                Text(clockText(binding.wrappedValue))
                    .font(.system(size: 29, weight: .medium, design: .rounded)).monospacedDigit()
                    .foregroundStyle(field.color)
                    .gesture(DragGesture(minimumDistance: 12)
                        .onChanged { change in
                            if dragOrigin == nil { dragOrigin = binding.wrappedValue }
                            let step = Int(change.translation.width / 8) * 5
                            binding.wrappedValue = min(3600, max(field == .work ? 1 : 0, (dragOrigin ?? 0) + step))
                        }
                        .onEnded { _ in dragOrigin = nil })
            }
            .padding(.horizontal, 19).padding(.vertical, 15)
            .foregroundStyle(Theme.cream)
            .background(field.color.opacity(0.075), in: RoundedRectangle(cornerRadius: 21))
            .overlay(RoundedRectangle(cornerRadius: 21).stroke(field.color.opacity(0.13), lineWidth: 1))
        }.buttonStyle(.plain)
            .accessibilityLabel("\(field.title), \(binding.wrappedValue) seconds. Double tap to edit.")
    }
    @State private var dragOrigin: Int?

    private func counterRow(_ title: String, subtitle: String, icon: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon).font(.system(size: 19)).frame(width: 27).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 17, weight: .semibold, design: .rounded))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Stepper(value: value, in: range) {
                Text("\(value.wrappedValue)").font(.system(size: 26, weight: .medium, design: .rounded))
                    .monospacedDigit().frame(minWidth: 30)
            }.fixedSize().accessibilityLabel(title)
        }.padding(.horizontal, 19).padding(.vertical, 13)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 21))
    }
}

private struct DurationEditor: View {
    let title: String
    @Binding var value: Int
    let minimum: Int
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                Picker("Minutes", selection: Binding(get: { value / 60 }, set: {
                    value = min(3600, max(minimum, $0 * 60 + value % 60))
                })) {
                    ForEach(0...60, id: \.self) { Text("\($0) min").tag($0) }
                }
                Picker("Seconds", selection: Binding(get: { value % 60 }, set: {
                    value = min(3600, max(minimum, value / 60 * 60 + $0))
                })) {
                    ForEach(0...59, id: \.self) { Text("\($0) sec").tag($0) }
                }
            }
            .pickerStyle(.wheel).padding()
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.preferredColorScheme(.dark)
    }
}

private struct ExerciseEditor: View {
    @EnvironmentObject private var store: WorkoutStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(0..<store.draft.rounds, id: \.self) { index in
                        TextField("Round \(index + 1)", text: Binding(get: {
                            store.draft.exercises.indices.contains(index) ? store.draft.exercises[index] : ""
                        }, set: { name in
                            while store.draft.exercises.count <= index { store.draft.exercises.append("") }
                            store.draft.exercises[index] = name
                        }))
                    }
                } header: { Text("Exercise names") } footer: {
                    Text("The same names repeat each set. Leave a name blank for a simple work interval.")
                }
            }
            .navigationTitle("Your circuit").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.preferredColorScheme(.dark)
    }
}
