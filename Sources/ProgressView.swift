import SwiftUI

struct ProgressView: View {
    @EnvironmentObject private var store: WorkoutStore
    @Binding var tab: Int
    private var completed: [WorkoutRecord] { store.history.filter(\.completed) }
    private var week: [Date] {
        let today = Calendar.current.startOfDay(for: .now)
        return (-6...0).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: today) }
    }
    private func seconds(on day: Date) -> Int {
        store.history.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }.reduce(0) { $0 + $1.duration }
    }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 0) {
                        stat("\(completed.count)", label: "COMPLETED")
                        Spacer()
                        stat("\(store.history.reduce(0) { $0 + $1.duration } / 60)", label: "MINUTES")
                    }.padding(8).listRowBackground(Theme.surface)
                }
                Section("Last 7 days") {
                    VStack(spacing: 14) {
                        HStack(alignment: .bottom, spacing: 12) {
                            ForEach(week, id: \.self) { day in
                                let amount = seconds(on: day)
                                VStack(spacing: 9) {
                                    Text(amount > 0 ? "\(amount / 60)m" : "")
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(amount > 0 ? Theme.lime : Theme.cream.opacity(0.08))
                                        .frame(height: max(6, CGFloat(amount) / CGFloat(max(1, week.map { seconds(on: $0) }.max() ?? 1)) * 95))
                                    Text(day.formatted(.dateTime.weekday(.narrow)))
                                        .font(.caption).foregroundStyle(.secondary)
                                }.frame(maxWidth: .infinity)
                                    .accessibilityElement(children: .ignore)
                                    .accessibilityLabel("\(day.formatted(date: .abbreviated, time: .omitted)): \(amount / 60) minutes")
                            }
                        }.frame(height: 140, alignment: .bottom)
                    }.padding(.vertical, 8).listRowBackground(Theme.surface)
                }
                Section("History · tap to repeat") {
                    if store.history.isEmpty {
                        VStack(alignment: .leading, spacing: 9) {
                            Text("Your first session starts here.").font(.headline)
                            Text("Finished and partial workouts appear here automatically when you close the timer.")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }.padding(.vertical, 18).listRowBackground(Theme.surface)
                    }
                    ForEach(store.history) { record in
                        Button {
                            store.draft = record.workout
                            tab = 0
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: record.completed ? "checkmark.circle.fill" : "circle.lefthalf.filled")
                                    .foregroundStyle(record.completed ? Theme.lime : Theme.orange)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(record.workout.name).font(.headline).foregroundStyle(Theme.cream)
                                    Text(record.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 5) {
                                    Text(clockText(record.duration)).monospacedDigit().foregroundStyle(Theme.cream)
                                    Text(record.completed ? "Completed" : "Partial").font(.caption2).foregroundStyle(.secondary)
                                }
                            }.padding(.vertical, 5)
                        }.listRowBackground(Theme.surface)
                    }
                    .onDelete { store.history.remove(atOffsets: $0) }
                }
            }
            .scrollContentBackground(.hidden).background(Theme.background)
            .navigationTitle("Your progress")
            .toolbar { if !store.history.isEmpty { EditButton() } }
        }
    }
    private func stat(_ value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value).font(.system(size: 39, weight: .semibold, design: .rounded)).foregroundStyle(Theme.lime)
            SmallLabel(title: label)
        }
    }
}
