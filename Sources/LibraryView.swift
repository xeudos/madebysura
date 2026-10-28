import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var store: WorkoutStore
    @Binding var tab: Int
    var body: some View {
        NavigationStack {
            List {
                if store.presets.isEmpty {
                    ContentUnavailableView("No favorites yet", systemImage: "star",
                        description: Text("Save a timer using the star on the Timer tab."))
                        .listRowBackground(Color.clear)
                }
                ForEach(store.presets) { workout in
                    Button {
                        store.draft = workout
                        tab = 0
                    } label: {
                        HStack(spacing: 15) {
                            Image(systemName: "timer").font(.system(size: 22, weight: .light))
                                .foregroundStyle(Theme.lime).frame(width: 47, height: 54)
                                .background(Theme.lime.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
                            VStack(alignment: .leading, spacing: 7) {
                                Text(workout.name).font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.primary).lineLimit(1)
                                Text("\(workout.rounds) rounds · \(workout.sets) sets")
                                    .font(.system(size: 12)).foregroundStyle(.secondary)
                                HStack(spacing: 8) {
                                    Text("\(clockText(workout.work)) work").foregroundStyle(Theme.lime)
                                    Text("\(clockText(workout.rest)) rest").foregroundStyle(Theme.red)
                                }.font(.system(size: 10, weight: .medium))
                            }
                            Spacer(minLength: 8)
                            VStack(alignment: .trailing, spacing: 8) {
                                Text(clockText(workout.totalDuration))
                                    .font(.system(size: 22, weight: .medium, design: .rounded))
                                    .monospacedDigit().foregroundStyle(.primary)
                                Text(workout.countdownSeconds == 0 ? "Cue off" : "\(workout.countdownSeconds)s cue")
                                    .font(.system(size: 10)).foregroundStyle(.secondary)
                            }
                        }.padding(16).panel()
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear).listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                }
                .onDelete { store.presets.remove(atOffsets: $0) }
                Section {
                    Button {
                        let names = Set(store.presets.map(\.name))
                        store.presets.append(contentsOf: Workout.presets.filter { !names.contains($0.name) })
                    } label: {
                        Label("Restore starter timers", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
                    }.listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain).scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Favorites")
            .toolbar { if !store.presets.isEmpty { EditButton().tint(Theme.lime) } }
        }
    }
}
