import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: WorkoutStore
    @State private var tab = 0
    var body: some View {
        TabView(selection: $tab) {
            TimerHome().tabItem { Label("Timer", systemImage: "timer") }.tag(0)
            LibraryView(tab: $tab).tabItem { Label("Favorites", systemImage: "star") }.tag(1)
            SettingsView().tabItem { Label("Settings", systemImage: "slider.horizontal.3") }.tag(2)
        }
        .tint(Theme.lime)
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
        case .rest: return Theme.red
        case .recovery: return Theme.purple
        case .prepare: return Theme.orange
        case .cooldown: return Theme.blue
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
    @State private var dragOrigin: Int?

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
                VStack(spacing: 20) {
                    summary
                    VStack(alignment: .leading, spacing: 10) {
                        SmallLabel(title: "Intervals").padding(.leading, 4)
                        VStack(spacing: 0) {
                            intervalRow(.prepare)
                            rowDivider
                            intervalRow(.work)
                            rowDivider
                            intervalRow(.rest)
                        }.panel()
                    }
                    HStack(spacing: 12) {
                        countCard("Rounds", value: $store.draft.rounds, range: 1...60)
                        countCard("Sets", value: $store.draft.sets, range: 1...20)
                    }
                    VStack(spacing: 0) {
                        if store.draft.sets > 1 {
                            intervalRow(.recovery)
                            rowDivider
                        }
                        intervalRow(.cooldown)
                    }.panel()

                    HStack(spacing: 12) {
                        Button { showExercises = true } label: {
                            Label("Exercises", systemImage: "list.bullet")
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                        }.accessibilityLabel("Name your exercises")
                        Menu {
                            ForEach(0...10, id: \.self) { seconds in
                                Button(seconds == 0 ? "Warning off" : "\(seconds) second warning") {
                                    store.countdownSeconds = seconds
                                }
                            }
                        } label: {
                            Label(store.countdownSeconds == 0 ? "Cue off" : "Cue · \(store.countdownSeconds)s",
                                  systemImage: "speaker.wave.2")
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                        }.accessibilityLabel("Countdown warning, \(store.countdownSeconds) seconds")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary).buttonStyle(.plain)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 17))

                    if let message = store.draft.validationMessage {
                        Text(message).font(.footnote).foregroundStyle(Theme.red)
                    }
                    Text("Tap to edit. Drag a time for quick adjustments.")
                        .font(.system(size: 11)).foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 18)
                .frame(maxWidth: 600).frame(maxWidth: .infinity)
            }
            .background(Theme.background)
            .navigationTitle("Interval")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                BigButton(title: "Start workout") { showSession = true }
                    .disabled(store.draft.validationMessage != nil)
                    .opacity(store.draft.validationMessage == nil ? 1 : 0.45)
                    .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 14)
                    .frame(maxWidth: 600).frame(maxWidth: .infinity)
                    .background(Theme.background)
            }
            .sheet(item: $editing) { field in
                DurationEditor(title: field.title, value: value(field), minimum: field == .work ? 1 : 0)
                    .presentationDetents([.height(330)]).presentationBackground(Theme.surface)
            }
            .sheet(isPresented: $showExercises) { ExerciseEditor() }
            .fullScreenCover(isPresented: $showSession) {
                SessionScreen(workout: store.draft, cue: store.cue, countdownSeconds: store.countdownSeconds,
                              haptics: store.haptics, awake: store.keepAwake)
            }
            .alert("Favorite saved", isPresented: $showSaved) {
                Button("Done", role: .cancel) {}
            } message: { Text("This timer and its countdown warning are saved in Favorites.") }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                TextField("Workout name", text: $store.draft.name)
                    .font(.system(size: 18, weight: .semibold))
                    .accessibilityLabel("Workout name")
                Button {
                    store.savePreset()
                    showSaved = true
                } label: {
                    Image(systemName: "star").font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Theme.lime).frame(width: 38, height: 38)
                        .background(Theme.lime.opacity(0.1), in: Circle())
                }.buttonStyle(.plain).accessibilityLabel("Save favorite timer")
                    .disabled(store.draft.validationMessage != nil)
            }
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    SmallLabel(title: "Total time")
                    Text(clockText(store.draft.totalDuration))
                        .font(.system(size: 46, weight: .medium, design: .rounded))
                        .tracking(-1.5).monospacedDigit()
                }
                Spacer()
                Text("\(store.draft.rounds * store.draft.sets) intervals")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                    .padding(.horizontal, 11).padding(.vertical, 7)
                    .background(Theme.elevated, in: Capsule()).padding(.bottom, 5)
            }
        }.padding(21).panel()
    }

    private var rowDivider: some View {
        Rectangle().fill(Theme.border.opacity(0.6)).frame(height: 0.5).padding(.leading, 70)
    }

    private func intervalRow(_ field: IntervalField) -> some View {
        let binding = value(field)
        return Button { editing = field } label: {
            HStack(spacing: 13) {
                Image(systemName: field.icon).font(.system(size: 17, weight: .medium))
                    .foregroundStyle(field.color).frame(width: 38, height: 38)
                    .background(field.color.opacity(0.11), in: RoundedRectangle(cornerRadius: 12))
                Text(field.title).font(.system(size: 15, weight: .medium)).foregroundStyle(.primary)
                Spacer(minLength: 10)
                Text(clockText(binding.wrappedValue))
                    .font(.system(size: 25, weight: .medium, design: .rounded))
                    .monospacedDigit().foregroundStyle(field.color)
                    .gesture(DragGesture(minimumDistance: 12)
                        .onChanged { change in
                            if dragOrigin == nil { dragOrigin = binding.wrappedValue }
                            let step = Int(change.translation.width / 8) * 5
                            binding.wrappedValue = min(3600, max(field == .work ? 1 : 0, (dragOrigin ?? 0) + step))
                        }.onEnded { _ in dragOrigin = nil })
                Image(systemName: "chevron.right").font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }.padding(.horizontal, 17).padding(.vertical, 13).contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityLabel("\(field.title), \(binding.wrappedValue) seconds. Double tap to edit.")
    }

    private func countCard(_ title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            SmallLabel(title: title)
            HStack {
                Button { if value.wrappedValue > range.lowerBound { value.wrappedValue -= 1 } } label: {
                    Image(systemName: "minus").font(.system(size: 12, weight: .semibold))
                        .frame(width: 32, height: 32).background(Theme.elevated, in: Circle())
                }.accessibilityLabel("Decrease \(title)")
                Spacer(minLength: 4)
                Text("\(value.wrappedValue)").font(.system(size: 29, weight: .medium, design: .rounded))
                    .monospacedDigit()
                Spacer(minLength: 4)
                Button { if value.wrappedValue < range.upperBound { value.wrappedValue += 1 } } label: {
                    Image(systemName: "plus").font(.system(size: 12, weight: .semibold))
                        .frame(width: 32, height: 32).background(Theme.elevated, in: Circle())
                }.accessibilityLabel("Increase \(title)")
            }.buttonStyle(.plain).foregroundStyle(.primary)
        }.padding(17).frame(maxWidth: .infinity).panel()
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
            }.pickerStyle(.wheel).padding()
                .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
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
                    Text("Names repeat each set. Leave a name blank for a simple work interval.")
                }.listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden).background(Theme.background)
            .navigationTitle("Your circuit").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
