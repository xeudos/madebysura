import UserNotifications
import Foundation
import Combine

@MainActor
protocol NotificationDelivery {
    func add(_ request: UNNotificationRequest) async throws
    func removePending(_ identifiers: [String])
    func removeDelivered(_ identifiers: [String])
}

@MainActor
private final class SystemNotificationDelivery: NotificationDelivery {
    private let center = UNUserNotificationCenter.current()
    func add(_ request: UNNotificationRequest) async throws { try await center.add(request) }
    func removePending(_ identifiers: [String]) { center.removePendingNotificationRequests(withIdentifiers: identifiers) }
    func removeDelivered(_ identifiers: [String]) { center.removeDeliveredNotifications(withIdentifiers: identifiers) }
}

/// Local alerts complement the continuously visible Live Activity.
@MainActor
final class PhaseNotifications: ObservableObject {
    private let center = UNUserNotificationCenter.current()
    private let delivery: NotificationDelivery
    private var identifiers: [String] = []
    private var completionIdentifier: String?
    private var pending: Task<Void, Never>?
    private var generation = 0
    private let prefix = "interval.\(UUID().uuidString)"
    @Published private(set) var status: String?
    @Published private(set) var permissionSummary = "Not checked"
    @Published private(set) var deliverySummary = ""
    private var authorized: Bool

    init(delivery: NotificationDelivery? = nil, authorized: Bool = false) {
        self.delivery = delivery ?? SystemNotificationDelivery()
        self.authorized = authorized
    }
    private func apply(_ settings: UNNotificationSettings) {
        authorized = [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus)
        switch settings.authorizationStatus {
        case .authorized, .ephemeral: permissionSummary = "Allowed"
        case .provisional: permissionSummary = "Quiet delivery"
        case .denied: permissionSummary = "Disabled"
        case .notDetermined: permissionSummary = "Not requested"
        @unknown default: permissionSummary = "Unknown"
        }
        if authorized {
            deliverySummary = [
                "Lock Screen: \(settings.lockScreenSetting == .enabled ? "on" : "off")",
                "Notification Center: \(settings.notificationCenterSetting == .enabled ? "on" : "off")",
                "Alerts: \(settings.alertSetting == .enabled ? "on" : "off")"
            ].joined(separator: " · ")
        } else { deliverySummary = "" }
    }
    private var permissionHelp: String {
        RuntimeEnvironment.isLiveContainer ? RuntimeEnvironment.notificationSetup
            : "Allow notifications in iPhone Settings → Interval → Notifications."
    }
    func refreshPermission() async {
        apply(await center.notificationSettings())
    }
    func authorize() async {
        do {
            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                _ = try await center.requestAuthorization(options: [.alert, .sound])
            }
            await refreshPermission()
            status = authorized ? nil : permissionHelp
        } catch {
            await refreshPermission()
            status = RuntimeEnvironment.isLiveContainer ? RuntimeEnvironment.notificationSetup
                : "Notifications could not be enabled: \(error.localizedDescription)"
        }
    }
    func sendTest() async {
        await authorize()
        guard authorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "Interval notification test"
        content.body = "Notifications are reaching this device. You're ready for your next workout."
        content.sound = .default
        content.threadIdentifier = "interval-test"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        do {
            try await delivery.add(UNNotificationRequest(identifier: "\(prefix).test", content: content, trigger: trigger))
            status = "Test scheduled in 5 seconds. Go Home or lock your iPhone now to check delivery."
        } catch {
            status = "The test could not be scheduled. \(permissionHelp)"
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
        if result.count > 60 { result = Array(result.prefix(59)) + [result[result.count - 1]] }
        return result
    }
    @discardableResult
    func schedule(workout: Workout, elapsed: Double) -> Task<Void, Never>? {
        cancel()
        guard authorized else { return nil }
        let revision = generation
        let events = Self.events(workout: workout, elapsed: elapsed)
        identifiers = events.indices.map { "\(prefix).\(revision).\($0)" }
        completionIdentifier = identifiers.last
        let ids = identifiers
        let scheduledAt = Date.now
        pending = Task { [self] in
            for (index, event) in events.enumerated() {
                guard !Task.isCancelled, revision == generation else { return }
                let content = UNMutableNotificationContent()
                content.title = event.title
                content.body = event.body
                content.threadIdentifier = "interval-workout"
                // Workout audio supplies sound; local alerts do not double the cues.
                let delay = max(0.1, event.delay - Date.now.timeIntervalSince(scheduledAt))
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
                do { try await delivery.add(UNNotificationRequest(identifier: ids[index], content: content, trigger: trigger)) }
                catch { status = "Some interval notifications could not be scheduled." }
                if Task.isCancelled || revision != generation {
                    delivery.removePending([ids[index]])
                    return
                }
            }
        }
        return pending
    }
    /// Finish cleanup after scheduling settles, retaining the final alert whether pending or delivered.
    @discardableResult
    func finish() -> Task<Void, Never> {
        let prior = pending
        let revision = generation
        let completion = completionIdentifier
        let obsolete = identifiers.filter { $0 != completion }
        let task = Task { [self] in
            await prior?.value
            guard !Task.isCancelled, revision == generation else { return }
            delivery.removePending(obsolete)
            delivery.removeDelivered(obsolete)
            identifiers = completion.map { [$0] } ?? []
        }
        pending = task
        return task
    }
    func cancel() {
        generation += 1
        pending?.cancel()
        pending = nil
        delivery.removePending(identifiers)
        delivery.removeDelivered(identifiers)
        identifiers = []
        completionIdentifier = nil
    }
}
