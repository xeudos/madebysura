import UserNotifications
import Foundation

/// Local alerts complement the continuously visible Live Activity.
@MainActor
final class PhaseNotifications {
    private let center = UNUserNotificationCenter.current()
    private var identifiers: [String] = []
    private var pending: Task<Void, Never>?
    private var generation = 0
    private let prefix = "interval.\(UUID().uuidString)"
    private(set) var status: String?
    private var authorized = false

    func authorize() async {
        do {
            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                authorized = try await center.requestAuthorization(options: [.alert, .sound])
            } else {
                authorized = [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus)
            }
            status = authorized ? nil : "Notifications are disabled. Allow them in iPhone Settings → Interval → Notifications."
        } catch {
            status = "Notifications could not be enabled: \(error.localizedDescription)"
        }
    }
    static func events(workout: Workout, elapsed: Double) -> [(delay: Double, title: String, body: String)] {
        var offset = 0.0
        var result: [(Double, String, String)] = []
        for phase in workout.phases {
            if offset > elapsed {
                result.append((offset - elapsed, phase.name,
                    "\(workout.name) · Round \(max(1, phase.round))/\(workout.rounds) · Set \(max(1, phase.set))/\(workout.sets)"))
            }
            offset += Double(phase.duration)
        }
        if offset > elapsed { result.append((offset - elapsed, "Workout complete", workout.name)) }
        // iOS limits pending local notifications. Always reserve the last slot for completion.
        if result.count > 60 { result = Array(result.prefix(59)) + [result[result.count - 1]] }
        return result
    }
    func schedule(workout: Workout, elapsed: Double) {
        cancel()
        guard authorized else { return }
        let revision = generation
        let events = Self.events(workout: workout, elapsed: elapsed)
        identifiers = events.indices.map { "\(prefix).\(revision).\($0)" }
        let ids = identifiers
        pending = Task { [self] in
            for (index, event) in events.enumerated() {
                guard !Task.isCancelled, revision == generation else { return }
                let content = UNMutableNotificationContent()
                content.title = event.title
                content.body = event.body
                content.threadIdentifier = "interval-workout"
                // The workout audio track supplies sound; avoid duplicate audible cues.
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(0.1, event.delay), repeats: false)
                do { try await center.add(UNNotificationRequest(identifier: ids[index], content: content, trigger: trigger)) }
                catch { status = "Some interval notifications could not be scheduled." }
                if Task.isCancelled || revision != generation {
                    center.removePendingNotificationRequests(withIdentifiers: [ids[index]])
                    return
                }
            }
        }
    }
    func cancel() {
        generation += 1
        pending?.cancel()
        pending = nil
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
        identifiers = []
    }
}
