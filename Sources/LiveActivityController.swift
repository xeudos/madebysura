import ActivityKit
import Foundation

@MainActor
final class LiveActivityController {
    private var activity: Activity<TimerActivityAttributes>?
    private var pending: Task<Void, Never>?
    private var lastKey = ""
    private(set) var unavailable = false

    static func clearOrphans() async {
        for activity in Activity<TimerActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
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
        let prior = pending
        pending = Task { [self] in
            await prior?.value
            let content = ActivityContent(state: state, staleDate: running ? state.phaseEnd : nil)
            if state.finished {
                if let activity = self.activity {
                    await activity.end(content, dismissalPolicy: .after(Date.now.addingTimeInterval(60)))
                }
                self.activity = nil
            } else if let activity = self.activity {
                await activity.update(content)
            } else if ActivityAuthorizationInfo().areActivitiesEnabled {
                do {
                    self.activity = try Activity.request(
                        attributes: TimerActivityAttributes(name: String(workout.name.prefix(70))),
                        content: content, pushType: nil)
                } catch { self.unavailable = true }
            } else { self.unavailable = true }
        }
    }
    func invalidate() { lastKey = "" }
    func end() {
        let prior = pending
        pending = Task { [self] in
            await prior?.value
            guard let activity = self.activity else { return }
            await activity.end(nil, dismissalPolicy: .immediate)
            self.activity = nil
        }
    }
}
