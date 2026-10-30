import Foundation

enum RuntimeEnvironment {
    static var isLiveContainer: Bool { isLiveContainer(environment: ProcessInfo.processInfo.environment) }
    static func isLiveContainer(environment: [String: String]) -> Bool {
        environment["LC_HOME_PATH"] != nil
    }
    static let liveActivityLimitation = "Live Activities are unavailable inside LiveContainer. Install Interval as a separate app with its widget extension to enable them."
    static let notificationSetup = "In LiveContainer, enable Fix Local Notifications in Interval’s app settings, then relaunch Interval. Also allow notifications for LiveContainer in iPhone Settings."
}
