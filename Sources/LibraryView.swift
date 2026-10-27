import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var store: WorkoutStore
    @Binding var tab: Int
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ready when you are.")
                            .font(.system(size: 30, weight: .bold, design: .rounded)).tracking(-0.7)
                        Text("Your favourite sessions, one tap away.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }.padding(.vertical, 12).listRowBackground(Color.clear)
                }
                Section("Favorite timers") {
                    ForEach(store.presets) { workout in
                        Button {
                            store.draft = workout
                            tab = 0
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "bolt.fill").font(.title3).foregroundStyle(Theme.lime)
                                    .frame(width: 44, height: 50)
                                    .background(Theme.lime.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                                VStack(alignment: .leading, spacing: 7) {
                                    Text(workout.name).font(.headline).foregroundStyle(Theme.cream)
                                    Text("\(workout.rounds) rounds · \(workout.sets) sets · \(clockText(workout.work))/\(clockText(workout.rest)) · \(workout.countdownSeconds)s cue")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(clockText(workout.totalDuration))
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(Theme.lime)
                            }.padding(.vertical, 8)
                        }.listRowBackground(Theme.surface)
                    }
                    .onDelete { store.presets.remove(atOffsets: $0) }
                }
                if store.presets.isEmpty {
                    Text("Save a workout from the Timer tab using the bookmark button.")
                        .foregroundStyle(.secondary).listRowBackground(Color.clear)
                }
                Section {
                    Button("Restore starter workouts") {
                        let names = Set(store.presets.map(\.name))
                        store.presets.append(contentsOf: Workout.presets.filter { !names.contains($0.name) })
                    }.foregroundStyle(Theme.lime).listRowBackground(Theme.surface)
                }
            }
            .scrollContentBackground(.hidden).background(Theme.background)
            .navigationTitle("Workouts")
            .toolbar { EditButton() }
        }
    }
}
