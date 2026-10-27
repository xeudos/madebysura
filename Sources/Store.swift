import Foundation
import SwiftUI

@MainActor
final class WorkoutStore: ObservableObject {
    @Published var draft: Workout { didSet { saveDraft() } }
    @Published var presets: [Workout] { didSet { save(presets, key: "presets.v1") } }
    @Published var history: [WorkoutRecord] { didSet { save(history, key: "history.v1") } }
    @Published var cue: CueMode { didSet { defaults.set(cue.rawValue, forKey: "cue.v1") } }
    @Published var countdownSeconds: Int { didSet { defaults.set(countdownSeconds, forKey: "countdown.v1") } }
    @Published var haptics: Bool { didSet { defaults.set(haptics, forKey: "haptics.v1") } }
    @Published var keepAwake: Bool { didSet { defaults.set(keepAwake, forKey: "awake.v1") } }
    @Published var storageError: String?
    private let defaults: UserDefaults
    private let folder: URL

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Interval", isDirectory: true)
        folder = base
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        func load<T: Decodable>(_ key: String, fallback: T) -> T {
            guard let data = try? Data(contentsOf: base.appendingPathComponent(key + ".json")),
                  let value = try? JSONDecoder().decode(T.self, from: data) else { return fallback }
            return value
        }
        let loaded: Workout = load("draft.v1", fallback: Workout())
        draft = loaded.validationMessage == nil ? loaded : Workout()
        presets = load("presets.v1", fallback: Workout.presets)
        history = load("history.v1", fallback: [])
        cue = CueMode(rawValue: defaults.string(forKey: "cue.v1") ?? "") ?? .voice
        countdownSeconds = defaults.object(forKey: "countdown.v1") == nil ? 3 : min(10, max(0, defaults.integer(forKey: "countdown.v1")))
        haptics = defaults.object(forKey: "haptics.v1") == nil ? true : defaults.bool(forKey: "haptics.v1")
        keepAwake = defaults.object(forKey: "awake.v1") == nil ? true : defaults.bool(forKey: "awake.v1")
    }
    private func saveDraft() { save(draft, key: "draft.v1") }
    private func save<T: Encodable>(_ value: T, key: String) {
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: folder.appendingPathComponent(key + ".json"), options: .atomic)
        } catch { storageError = "Your latest changes could not be saved. Please check available storage." }
    }
    func savePreset() {
        var copy = draft
        copy.id = UUID()
        if copy.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { copy.name = "My intervals" }
        presets.append(copy)
    }
    func record(_ record: WorkoutRecord) {
        history.insert(record, at: 0)
        if history.count > 1000 { history = Array(history.prefix(1000)) }
    }
}
