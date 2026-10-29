import SwiftUI
import Combine
import AVFoundation

@MainActor
final class WorkoutSession: ObservableObject {
    let workout: Workout
    let phases: [WorkoutPhase]
    let cue: CueMode
    let countdownSeconds: Int
    @Published private(set) var snapshot: TimelineSnapshot
    @Published private(set) var running = false
    @Published private(set) var preparing = true
    @Published private(set) var finished = false
    @Published private(set) var skipCountdown: Int?
    private var skipTask: Task<Void, Never>?
    private let skipDelay: Bool
    @Published var error: String?
    @Published private(set) var actualSeconds: Double = 0

    private let live = LiveActivityController()
    private let liveEnabled: Bool
    private var timer: Timer?
    private var beganAt: ContinuousClock.Instant?
    private var carried = 0.0
    private var accountedAt = 0.0
    private var lastCue = ""
    private var guide = AudioGuide()
    private var observer: NSObjectProtocol?
    private let haptics: Bool
    private let awake: Bool

    init(workout: Workout, cue: CueMode, countdownSeconds: Int, haptics: Bool, awake: Bool, liveActivities: Bool = true, skipDelay: Bool = true) {
        self.skipDelay = skipDelay
        self.liveEnabled = liveActivities
        self.workout = workout
        self.phases = workout.phases
        self.cue = cue
        self.countdownSeconds = countdownSeconds
        self.haptics = haptics
        self.awake = awake
        snapshot = .at(0, phases: workout.phases)
    }
    var phase: WorkoutPhase? {
        phases.indices.contains(snapshot.index) ? phases[snapshot.index] : nil
    }
    var nextPhase: WorkoutPhase? {
        phases.indices.contains(snapshot.index + 1) ? phases[snapshot.index + 1] : nil
    }
    private var elapsed: Double {
        guard let beganAt else { return carried }
        let duration = beganAt.duration(to: .now).components
        return carried + Double(duration.seconds) + Double(duration.attoseconds) / 1e18
    }

    func start() async {
        guard preparing else { return }
        guide.mode = cue
        guide.countdownSeconds = countdownSeconds
        do { try await guide.prepare(phases: phases) }
        catch { self.error = "Audio could not start. You can continue with the on-screen timer." }
        preparing = false
        observer = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { [weak self] notification in
            guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  raw == AVAudioSession.InterruptionType.began.rawValue else { return }
            Task { @MainActor in self?.pause() }
        }
        resume()
    }
    func resume() {
        guard !finished, !preparing, !running else { return }
        beganAt = .now
        accountedAt = carried
        running = true
        UIApplication.shared.isIdleTimerDisabled = awake
        guide.play(at: carried)
        update()
        let newTimer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.update() }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }
    func pause() {
        guard running else { return }
        update()
        if finished { return }
        carried = elapsed
        beganAt = nil
        running = false
        timer?.invalidate()
        timer = nil
        guide.pause()
        UIApplication.shared.isIdleTimerDisabled = false
        publishLive()
    }
    func toggle() { running ? pause() : resume() }

    func requestSkip() {
        guard !preparing, !finished else { return }
        if skipCountdown != nil { finishSkip(); return }
        guard skipDelay && running else { skip(); return }
        pause()
        guard !finished else { return }
        skipCountdown = 3
        guide.warning(3)
        skipTask = Task { [weak self] in
            do {
                for seconds in [2, 1] {
                    try await Task.sleep(for: .seconds(1))
                    guard let self, !Task.isCancelled else { return }
                    self.skipCountdown = seconds
                    self.guide.warning(seconds)
                }
                try await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled else { return }
                self.finishSkip()
            } catch { }
        }
    }
    private func finishSkip() {
        skipTask?.cancel()
        skipTask = nil
        skipCountdown = nil
        skip()
        if !finished { resume() }
    }
    func skip() {
        guard !finished, !preparing else { return }
        if running { update() }
        guard !finished else { return }
        carried = Double(phases.prefix(snapshot.index + 1).reduce(0) { $0 + $1.duration })
        accountedAt = carried
        if running {
            beganAt = .now
            guide.play(at: carried)
        }
        lastCue = ""
        update()
    }
    func restartInterval() {
        guard !preparing, !finished else { return }
        if running { update() }
        guard !finished else { return }
        carried = Double(phases.prefix(snapshot.index).reduce(0) { $0 + $1.duration })
        accountedAt = carried
        if running { beganAt = .now; guide.play(at: carried) }
        live.invalidate()
        lastCue = ""
        update()
    }
    private func publishLive() {
        if liveEnabled { live.sync(workout: workout, phase: phase, snapshot: snapshot, running: running) }
    }
    func refresh() { if running { update() } }
    private func update() {
        defer { publishLive() }
        let time = elapsed
        if running {
            actualSeconds += max(0, min(time, Double(workout.totalDuration)) - accountedAt)
            accountedAt = min(time, Double(workout.totalDuration))
        }
        let previous = snapshot
        snapshot = .at(time, phases: phases)
        if snapshot.finished {
            finished = true
            running = false
            carried = Double(workout.totalDuration)
            beganAt = nil
            timer?.invalidate()
            timer = nil
            UIApplication.shared.isIdleTimerDisabled = false
            guide.say("Workout complete. Well done!")
            if haptics { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        } else if running, let phase {
            if previous.index != snapshot.index || lastCue.isEmpty {
                guide.say(phase.kind == .work
                          ? "\(phase.name). Round \(phase.round) of \(workout.rounds)."
                          : phase.name)
                if haptics && UIApplication.shared.applicationState == .active {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
                lastCue = "\(snapshot.index)-\(snapshot.remaining)"
            } else if snapshot.remaining <= countdownSeconds && snapshot.remaining > 0 {
                let key = "\(snapshot.index)-\(snapshot.remaining)"
                if key != lastCue {
                    if cue == .voice { guide.say("\(snapshot.remaining)") }
                    if haptics && UIApplication.shared.applicationState == .active {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    lastCue = key
                }
            }
        }
    }
    func end() {
        skipTask?.cancel()
        skipTask = nil
        skipCountdown = nil
        if running { pause() }
        timer?.invalidate()
        timer = nil
        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
        live.end()
        guide.stop()
        UIApplication.shared.isIdleTimerDisabled = false
    }
}
