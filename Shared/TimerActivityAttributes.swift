import ActivityKit
import Foundation

struct TimerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var title: String
        var kind: String
        var round: Int
        var rounds: Int
        var set: Int
        var sets: Int
        var phaseStart: Date
        var phaseEnd: Date
        var sessionEnd: Date
        var remaining: Int
        var paused: Bool
        var finished: Bool
    }
    var name: String
}
