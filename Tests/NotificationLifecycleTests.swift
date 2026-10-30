import XCTest
import UserNotifications
@testable import Interval

@MainActor
private final class RecordingNotificationDelivery: NotificationDelivery {
    var requests: [String: UNNotificationRequest] = [:]
    var removedDelivered: Set<String> = []
    func add(_ request: UNNotificationRequest) async throws { requests[request.identifier] = request }
    func removePending(_ identifiers: [String]) { for id in identifiers { requests.removeValue(forKey: id) } }
    func removeDelivered(_ identifiers: [String]) { removedDelivered.formUnion(identifiers) }
}

final class NotificationLifecycleTests: XCTestCase {
    @MainActor
    func testFinishingDuringSchedulingKeepsCompletionAlert() async throws {
        let delivery = RecordingNotificationDelivery()
        let notifications = PhaseNotifications(delivery: delivery, authorized: true)
        let workout = Workout(prepare: 0, work: 30, rest: 10, rounds: 2, sets: 1, recovery: 0, cooldown: 0)
        notifications.schedule(workout: workout, elapsed: 0)
        // Finish before the async queue has run: completion must still be scheduled and retained.
        await notifications.finish().value
        let final = try XCTUnwrap(delivery.requests.values.first)
        XCTAssertEqual(delivery.requests.count, 1)
        XCTAssertEqual(final.content.title, "Workout complete")
        XCTAssertFalse(delivery.removedDelivered.contains(final.identifier))
        // Closing an already-completed session must be safe to repeat.
        await notifications.finish().value
        XCTAssertNotNil(delivery.requests[final.identifier])
    }
    @MainActor
    func testEarlyEndCancelsCompletionAndIntervalAlerts() async {
        let delivery = RecordingNotificationDelivery()
        let notifications = PhaseNotifications(delivery: delivery, authorized: true)
        await notifications.schedule(workout: Workout(), elapsed: 0)?.value
        XCTAssertGreaterThan(delivery.requests.count, 1)
        let queued = Set(delivery.requests.keys)
        notifications.cancel()
        XCTAssertTrue(delivery.requests.isEmpty)
        XCTAssertTrue(queued.isSubset(of: delivery.removedDelivered))
    }
}
