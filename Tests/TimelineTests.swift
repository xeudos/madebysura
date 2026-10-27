import XCTest
@testable import Interval

final class TimelineTests: XCTestCase {
    func testNoRestAfterFinalRoundOrBetweenSets() {
        let w = Workout(name: "Test", prepare: 3, work: 10, rest: 5, rounds: 2, sets: 2, recovery: 9, cooldown: 4)
        XCTAssertEqual(w.phases.map(\.kind), [.prepare, .work, .rest, .work, .recover, .work, .rest, .work, .cooldown])
        XCTAssertEqual(w.totalDuration, 66)
        XCTAssertEqual(w.phases.reduce(0) { $0 + $1.duration }, w.totalDuration)
        XCTAssertEqual(w.phases.filter { $0.kind == .work }.map(\.set), [1, 1, 2, 2])
    }
    func testExactBoundariesAndLongWakeUp() {
        let w = Workout(prepare: 3, work: 10, rest: 5, rounds: 2, sets: 1, recovery: 0, cooldown: 0)
        let p = w.phases
        XCTAssertEqual(TimelineSnapshot.at(0, phases: p).remaining, 3)
        XCTAssertEqual(TimelineSnapshot.at(2.1, phases: p).remaining, 1)
        XCTAssertEqual(TimelineSnapshot.at(3, phases: p).index, 1)
        XCTAssertEqual(TimelineSnapshot.at(13, phases: p).index, 2)
        XCTAssertEqual(TimelineSnapshot.at(18, phases: p).index, 3)
        XCTAssertTrue(TimelineSnapshot.at(28, phases: p).finished)
        XCTAssertTrue(TimelineSnapshot.at(100000, phases: p).finished)
        XCTAssertEqual(TimelineSnapshot.at(-5, phases: p).progress, 0)
    }
    func testZeroOptionalPhasesAndSingleRound() {
        let w = Workout(prepare: 0, work: 1, rest: 0, rounds: 1, sets: 1, recovery: 0, cooldown: 0)
        XCTAssertEqual(w.phases.count, 1)
        XCTAssertEqual(w.totalDuration, 1)
        XCTAssertFalse(TimelineSnapshot.at(0.999, phases: w.phases).finished)
        XCTAssertTrue(TimelineSnapshot.at(1, phases: w.phases).finished)
    }
    func testNamesValidationAndPersistence() throws {
        var w = Workout(exercises: ["Squats", "  ", "Plank"])
        XCTAssertEqual(w.phases.filter { $0.kind == .work }.prefix(3).map(\.name), ["Squats", "Work", "Plank"])
        let encoded = try JSONEncoder().encode(w)
        XCTAssertEqual(try JSONDecoder().decode(Workout.self, from: encoded), w)
        w.work = 0
        XCTAssertNotNil(w.validationMessage)
        w.work = 3600
        w.rounds = 60
        XCTAssertNotNil(w.validationMessage)
    }
    func testDurationAccountingAcrossPresets() {
        for w in Workout.presets {
            XCTAssertNil(w.validationMessage)
            XCTAssertEqual(w.phases.reduce(0) { $0 + $1.duration }, w.totalDuration)
            XCTAssertEqual(w.phases.filter { $0.kind == .work }.reduce(0) { $0 + $1.duration }, w.workDuration)
        }
    }
    func testThreeOrFiveSecondCountdownAndShortIntervals() {
        XCTAssertEqual(CountdownSchedule.seconds(duration: 10, lead: 3), [3, 2, 1])
        XCTAssertEqual(CountdownSchedule.seconds(duration: 10, lead: 5), [5, 4, 3, 2, 1])
        XCTAssertEqual(CountdownSchedule.seconds(duration: 2, lead: 5), [1])
        XCTAssertEqual(CountdownSchedule.seconds(duration: 1, lead: 5), [])
        XCTAssertEqual(CountdownSchedule.seconds(duration: 10, lead: 0), [])
    }
    func testFavoritesKeepIndependentCountdownPreferences() throws {
        var a = Workout(name: "Short warm-up")
        a.countdownSeconds = 3
        var b = Workout(name: "Long warning")
        b.countdownSeconds = 5
        let decoded = try JSONDecoder().decode([Workout].self, from: JSONEncoder().encode([a, b]))
        XCTAssertEqual(decoded.map(\.countdownSeconds), [3, 5])
        XCTAssertNotEqual(decoded[0].id, decoded[1].id)
    }
    func testFormats() {
        XCTAssertEqual(clockText(5), "00:05")
        XCTAssertEqual(clockText(65), "01:05")
        XCTAssertEqual(clockText(3601), "1:00:01")
    }
}
