import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: WorkoutStore
    @State private var tab = 0
    var body: some View {
        TabView(selection: $tab) {
            TimerHome().tabItem { Label("Timer", systemImage: "timer") }.tag(0)
            LibraryView(tab: $tab).tabItem { Label("Favorites", systemImage: "star") }.tag(1)
            ProgressView(tab: $tab).tabItem { Label("History", systemImage: "clock.arrow.circlepath") }.tag(2)
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
        case .rest: return Theme.red
        case .recovery: return Color(red: 0.58, green: 0.43, blue: 0.76)
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
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        TextField("Workout name", text: $store.draft.name)
                            .font(.system(size: 20, weight: .medium))
                            .accessibilityLabel("Workout name")
                        Button {
                            store.savePreset()
                            showSaved = true
                        } label: {
                            Image(systemName: "star").font(.system(size: 24))
                                .foregroundStyle(Theme.blue)
                        }.accessibilityLabel("Save favorite timer")
                            .disabled(store.draft.validationMessage != nil)
                    }.padding(.horizontal, 5).padding(.top, 4).padding(.bottom, 2)

                    HStack {
                        Text("TOTAL TIME").font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(clockText(store.draft.totalDuration))
                            .font(.system(size: 27, weight: .light)).monospacedDigit()
                    }.padding(.horizontal, 5).padding(.bottom, 2)

                    VStack(spacing: 6) {
                        intervalRow(.prepare)
                        intervalRow(.work)
                        intervalRow(.rest)
                        counterRow("Rounds", subtitle: "per set", icon: "repeat",
                                   value: $store.draft.rounds, range: 1...60)
                        counterRow("Sets", subtitle: "complete circuits", icon: "square.stack",
                                   value: $store.draft.sets, range: 1...20)
                        if store.draft.sets > 1 { intervalRow(.recovery) }
                        intervalRow(.cooldown)
                    }

                    HStack {
                        Button { showExercises = true } label: {
                            Label("Exercise names", systemImage: "list.bullet")
                        }
                        Spacer()
                        Menu {
                            ForEach([0, 3, 5, 10], id: \.self) { seconds in
                                Button(seconds == 0 ? "Warning off" : "\(seconds) second warning") {
                                    store.countdownSeconds = seconds
                                }
                            }
                        } label: {
                            Label("\(store.countdownSeconds)s warning", systemImage: "speaker.wave.2")
                        }
                    }.font(.system(size: 13)).padding(.vertical, 5).tint(Theme.blue)

                    if let message = store.draft.validationMessage {
                        Text(message).font(.callout).foregroundStyle(Theme.red)
                    }
                    BigButton(title: "START") { showSession = true }
                        .disabled(store.draft.validationMessage != nil)
                        .opacity(store.draft.validationMessage == nil ? 1 : 0.4)
                    Text("Drag a time to adjust · Tap for minutes & seconds")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 20)
                .frame(maxWidth: 620).frame(maxWidth: .infinity)
            }
            .background(Theme.background)
            .navigationTitle("Interval Timer").navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editing) { field in
                DurationEditor(title: field.title, value: value(field), minimum: field == .work ? 1 : 0)
                    .presentationDetents([.height(350)])
            }
            .sheet(isPresented: $showExercises) { ExerciseEditor() }
            .fullScreenCover(isPresented: $showSession) {
                SessionScreen(workout: store.draft, cue: store.cue, countdownSeconds: store.countdownSeconds,
                              haptics: store.haptics, awake: store.keepAwake)
            }
            .alert("Favorite saved", isPresented: $showSaved) {
                Button("Done", role: .cancel) {}
            } message: { Text("Find this timer in Favorites. Its countdown warning is saved too.") }
        }
    }

    private func intervalRow(_ field: IntervalField) -> some View {
        let binding = value(field)
        return Button { editing = field } label: {
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(field.title.uppercased()).font(.system(size: 16, weight: .semibold))
                    Image(systemName: field.icon).font(.system(size: 19, weight: .light))
                        .opacity(0.8)
                }
                Spacer()
                Text(clockText(binding.wrappedValue))
                    .font(.system(size: 45, weight: .ultraLight)).monospacedDigit()
                    .gesture(DragGesture(minimumDistance: 12)
                        .onChanged { change in
                            if dragOrigin == nil { dragOrigin = binding.wrappedValue }
                            let step = Int(change.translation.width / 8) * 5
                            binding.wrappedValue = min(3600, max(field == .work ? 1 : 0, (dragOrigin ?? 0) + step))
                        }.onEnded { _ in dragOrigin = nil })
                Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold)).opacity(0.6)
            }
            .padding(.horizontal, 21).padding(.vertical, 12)
            .foregroundStyle(.white)
            .background(field.color, in: RoundedRectangle(cornerRadius: 8))
        }.buttonStyle(.plain)
            .accessibilityLabel("\(field.title), \(binding.wrappedValue) seconds. Double tap to edit.")
    }
    @State private var dragOrigin: Int?

    private func counterRow(_ title: String, subtitle: String, icon: String,
                            value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title.uppercased()).font(.system(size: 15, weight: .semibold))
                Text(subtitle).font(.system(size: 11)).opacity(0.8)
            }
            Spacer()
            Button { if value.wrappedValue > range.lowerBound { value.wrappedValue -= 1 } } label: {
                Image(systemName: "minus.circle").font(.system(size: 26, weight: .ultraLight))
                    .frame(width: 42, height: 42)
            }.accessibilityLabel("Decrease \(title)")
            Text("\(value.wrappedValue)").font(.system(size: 36, weight: .ultraLight))
                .monospacedDigit().frame(minWidth: 48)
            Button { if value.wrappedValue < range.upperBound { value.wrappedValue += 1 } } label: {
                Image(systemName: "plus.circle").font(.system(size: 26, weight: .ultraLight))
                    .frame(width: 42, height: 42)
            }.accessibilityLabel("Increase \(title)")
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 21).padding(.vertical, 7)
        .foregroundStyle(.white)
        .background(title == "Rounds" ? Theme.blue : Color(red: 0.42, green: 0.48, blue: 0.61),
                    in: RoundedRectangle(cornerRadius: 8))
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
        }.preferredColorScheme(.light)
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
        }.preferredColorScheme(.light)
    }
}
