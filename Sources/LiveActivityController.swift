import ActivityKit
import Combine
import UIKit

@MainActor
final class LiveActivityController: ObservableObject {
    @Published private(set) var status = "Starting Live Activity…"
    @Published private(set) var issue: String?
    @Published private(set) var active = false
    private var activity: Activity<TimerActivityAttributes>?
    private var pending: Task<Void, Never>?
    private var observation: Task<Void, Never>?
    private var lastKey = ""

    static var extensionInstalled: Bool {
        guard let url = Bundle.main.builtInPlugInsURL,
              let children = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else { return false }
        return children.contains { url in
            guard let bundle = Bundle(url: url),
                  let info = bundle.infoDictionary?["NSExtension"] as? [String: Any] else { return false }
            return info["NSExtensionPointIdentifier"] as? String == "com.apple.widgetkit-extension"
        }
    }

    static func clearOrphans() async {
        for activity in Activity<TimerActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
    private func fail(_ message: String) {
        active = false
        issue = message
        status = message
    }
    func sync(workout: Workout, phase: WorkoutPhase?, snapshot: TimelineSnapshot, running: Bool) {
        guard let phase else { return }
        let key = "\(snapshot.index)-\(running)-\(snapshot.finished)"
        guard key != lastKey else { return }
        lastKey = key
        let now = Date.now
        let state = TimerActivityAttributes.ContentState(
            title: String(phase.name.prefix(70)), kind: phase.kind.rawValue,
            round: max(1, phase.round), rounds: workout.rounds, set: max(1, phase.set), sets: workout.sets,
            phaseStart: now.addingTimeInterval(-Double(phase.duration - snapshot.remaining)),
            phaseEnd: now.addingTimeInterval(Double(snapshot.remaining)),
            sessionEnd: now.addingTimeInterval(Double(snapshot.totalRemaining)),
            remaining: snapshot.remaining, paused: !running, finished: snapshot.finished)
        let content = ActivityContent(state: state, staleDate: running ? state.phaseEnd : nil)

        // Request synchronously while the app is visible, before audio preparation or permission sheets.
        if activity == nil && !snapshot.finished {
            guard Self.extensionInstalled else {
                fail("Live Activity unavailable: widget extension is missing. Reinstall with app extensions included.")
                return
            }
            guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                fail("Live Activities are disabled. Allow them in iPhone Settings → Interval.")
                return
            }
            guard UIApplication.shared.applicationState == .active else {
                fail("Return to the timer to start its Live Activity.")
                return
            }
            do {
                let created = try Activity.request(
                    attributes: TimerActivityAttributes(name: String(workout.name.prefix(70))),
                    content: content, pushType: nil)
                activity = created
                active = true
                issue = nil
                status = "Live Activity active · Go Home or lock your iPhone to view it."
                observation?.cancel()
                observation = Task { [weak self] in
                    for await state in created.activityStateUpdates {
                        guard !Task.isCancelled, let self else { return }
                        if state == .dismissed || state == .ended {
                            if self.activity?.id == created.id {
                                self.activity = nil
                                self.active = false
                                self.status = "Live Activity ended."
                            }
                            return
                        }
                    }
                }
            } catch {
                fail("Live Activity could not start: \(String(describing: error)). Check iPhone Settings and keep the widget extension when signing.")
            }
            return
        }
        guard let activity else { return }
        let prior = pending
        pending = Task { [self] in
            await prior?.value
            if state.finished {
                await activity.end(content, dismissalPolicy: .after(Date.now.addingTimeInterval(60)))
                self.activity = nil
                active = false
                status = "Workout complete."
            } else {
                await activity.update(content)
            }
        }
    }
    func invalidate() { lastKey = "" }
    func end() {
        observation?.cancel()
        let prior = pending
        let ending = activity
        activity = nil
        active = false
        pending = Task {
            await prior?.value
            if let ending { await ending.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
