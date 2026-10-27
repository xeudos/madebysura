import Foundation

enum PhaseKind: String, Codable {
    case prepare, work, rest, recover, cooldown
    var title: String {
        switch self {
        case .prepare: return "Get ready"
        case .work: return "Work"
        case .rest: return "Rest"
        case .recover: return "Set recovery"
        case .cooldown: return "Cool down"
        }
    }
}

struct Workout: Codable, Identifiable, Equatable {
    var id = UUID()
    var name = "My intervals"
    var prepare = 10
    var work = 30
    var rest = 15
    var rounds = 8
    var sets = 1
    var recovery = 60
    var cooldown = 30
    var exercises: [String] = []

    var validationMessage: String? {
        guard (1...3600).contains(work) else { return "Work must be between 1 second and 60 minutes." }
        guard [prepare, rest, recovery, cooldown].allSatisfy({ (0...3600).contains($0) }) else {
            return "Each interval must be between 0 and 60 minutes."
        }
        guard (1...60).contains(rounds), (1...20).contains(sets) else {
            return "Choose 1–60 rounds and 1–20 sets."
        }
        guard totalDuration <= 10800 else { return "Keep the total workout under 3 hours." }
        return nil
    }
    var totalDuration: Int {
        prepare + sets * (rounds * work + max(0, rounds - 1) * rest)
        + max(0, sets - 1) * recovery + cooldown
    }
    var workDuration: Int { sets * rounds * work }
    var phases: [WorkoutPhase] {
        var result: [WorkoutPhase] = []
        func append(_ kind: PhaseKind, _ seconds: Int, _ round: Int = 0, _ set: Int = 0, _ name: String? = nil) {
            if seconds > 0 {
                result.append(WorkoutPhase(kind: kind, duration: seconds, round: round, set: set, name: name ?? kind.title))
            }
        }
        append(.prepare, prepare)
        for set in 1...max(1, sets) {
            for round in 1...max(1, rounds) {
                let custom = exercises.indices.contains(round - 1) ? exercises[round - 1].trimmingCharacters(in: .whitespacesAndNewlines) : ""
                append(.work, work, round, set, custom.isEmpty ? "Work" : custom)
                if round < rounds { append(.rest, rest, round, set) }
            }
            if set < sets { append(.recover, recovery, rounds, set) }
        }
        append(.cooldown, cooldown, rounds, sets)
        return result
    }

    static var presets: [Workout] {
        [
            Workout(name: "Tabata", prepare: 10, work: 20, rest: 10, rounds: 8, sets: 1, recovery: 60, cooldown: 30),
            Workout(name: "Classic HIIT", prepare: 10, work: 40, rest: 20, rounds: 10, sets: 1, recovery: 60, cooldown: 30),
            Workout(name: "Strength circuit", prepare: 15, work: 45, rest: 20, rounds: 4, sets: 3, recovery: 90, cooldown: 60,
                    exercises: ["Squats", "Push-ups", "Lunges", "Plank"])
        ]
    }
}

struct WorkoutPhase: Equatable {
    let kind: PhaseKind
    let duration: Int
    let round: Int
    let set: Int
    let name: String
}

struct TimelineSnapshot: Equatable {
    let index: Int
    let remaining: Int
    let totalRemaining: Int
    let phaseProgress: Double
    let progress: Double
    let finished: Bool

    static func at(_ elapsed: Double, phases: [WorkoutPhase]) -> TimelineSnapshot {
        let total = phases.reduce(0) { $0 + $1.duration }
        let time = max(0, elapsed)
        var start = 0
        for (index, phase) in phases.enumerated() {
            let end = start + phase.duration
            if time < Double(end) {
                return TimelineSnapshot(index: index, remaining: Int(ceil(Double(end) - time)),
                    totalRemaining: Int(ceil(Double(total) - time)),
                    phaseProgress: min(1, max(0, (time - Double(start)) / Double(phase.duration))),
                    progress: min(1, time / Double(max(1, total))), finished: false)
            }
            start = end
        }
        return TimelineSnapshot(index: max(0, phases.count - 1), remaining: 0, totalRemaining: 0,
                                phaseProgress: 1, progress: 1, finished: true)
    }
}

enum CueMode: String, CaseIterable, Codable {
    case voice = "Voice", beeps = "Beeps", off = "Off"
}

struct WorkoutRecord: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let workout: Workout
    let duration: Int
    let completed: Bool
}

func clockText(_ seconds: Int) -> String {
    let value = max(0, seconds)
    if value >= 3600 {
        return String(format: "%d:%02d:%02d", value / 3600, (value % 3600) / 60, value % 60)
    }
    return String(format: "%02d:%02d", value / 60, value % 60)
}
