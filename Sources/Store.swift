import Foundation
import SwiftUI

@MainActor
final class WorkoutStore: ObservableObject {
    @Published var draft: Workout { didSet { save(draft, key: "draft.v1") } }
    @Published var presets: [Workout] { didSet { save(presets, key: "presets.v1") } }
    @Published var appearance: AppearanceMode { didSet { defaults.set(appearance.rawValue, forKey: "appearance.v1") } }
    @Published var skipDelay: Bool { didSet { defaults.set(skipDelay, forKey: "skipDelay.v1") } }
    @Published var liveActivities: Bool { didSet { defaults.set(liveActivities, forKey: "live.v1") } }
    @Published var cue: CueMode { didSet { defaults.set(cue.rawValue, forKey: "cue.v1") } }
    @Published var haptics: Bool { didSet { defaults.set(haptics, forKey: "haptics.v1") } }
    @Published var keepAwake: Bool { didSet { defaults.set(keepAwake, forKey: "awake.v1") } }
    @Published var storageError: String?
    var countdownSeconds: Int {
        get { draft.countdownSeconds }
        set { draft.countdownSeconds = min(10, max(0, newValue)) }
    }
    private let defaults: UserDefaults
    private let folder: URL

    init(defaults: UserDefaults = .standard, storageFolder: URL? = nil) {
        self.defaults = defaults
        let base = storageFolder ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
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
        appearance = AppearanceMode(rawValue: defaults.string(forKey: "appearance.v1") ?? "") ?? .dark
        skipDelay = defaults.object(forKey: "skipDelay.v1") == nil ? true : defaults.bool(forKey: "skipDelay.v1")
        liveActivities = defaults.object(forKey: "live.v1") == nil ? true : defaults.bool(forKey: "live.v1")
        cue = CueMode(rawValue: defaults.string(forKey: "cue.v1") ?? "") ?? .voice
        haptics = defaults.object(forKey: "haptics.v1") == nil ? true : defaults.bool(forKey: "haptics.v1")
        keepAwake = defaults.object(forKey: "awake.v1") == nil ? true : defaults.bool(forKey: "awake.v1")
    }
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
}

extension WorkoutStore {
    func updateFavorite() {
        guard draft.validationMessage == nil, let index = presets.firstIndex(where: { $0.id == draft.id }) else { return }
        presets[index] = draft
    }
    func duplicateFavorite(_ workout: Workout) {
        var copy = workout
        copy.id = UUID()
        copy.name += " copy"
        presets.append(copy)
    }
}
