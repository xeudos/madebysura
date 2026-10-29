import AVFoundation

/// The audible cue track is rendered ahead of playback. iOS can play the real
/// interval/countdown sounds with the screen locked without relying on timers.
final class AudioGuide {
    private var player: AVAudioPlayer?
    private var skipPlayer: AVAudioPlayer?
    private let speech = AVSpeechSynthesizer()
    private var trackURL: URL?
    var mode: CueMode = .voice
    var countdownSeconds = 3

    func prepare(phases: [WorkoutPhase]) async throws {
        stop()
        guard mode != .off else { return }
        let countdown = countdownSeconds
        let url = try await Task.detached(priority: .userInitiated) {
            try Self.makeTrack(phases: phases, countdownSeconds: countdown)
        }.value
        trackURL = url
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
        player = try AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        player?.volume = mode == .voice ? 0.45 : 0.9
    }

    func play(at elapsed: Double) {
        guard mode != .off else { return }
        skipPlayer?.stop()
        player?.currentTime = elapsed
        player?.play()
    }
    func warning(_ seconds: Int) {
        if mode == .voice { say("\(seconds)") }
    }
    /// A separate, short PCM track gives immediate feedback in voice AND beep mode.
    /// Its three tones keep playing even when the UI's countdown task is suspended.
    func startSkipCountdown() {
        guard mode != .off else { return }
        do {
            skipPlayer = try AVAudioPlayer(data: Self.skipCountdownAudio())
            skipPlayer?.volume = 0.9
            skipPlayer?.prepareToPlay()
            skipPlayer?.play()
        } catch { }
        warning(3)
    }
    static func skipCountdownAudio() -> Data {
        let rate = 16000
        let samples = rate * 3
        var data = Data()
        func text(_ value: String) { data.append(contentsOf: value.utf8) }
        func u16(_ value: UInt16) { var n = value.littleEndian; withUnsafeBytes(of: &n) { data.append(contentsOf: $0) } }
        func u32(_ value: UInt32) { var n = value.littleEndian; withUnsafeBytes(of: &n) { data.append(contentsOf: $0) } }
        text("RIFF"); u32(UInt32(36 + samples * 2)); text("WAVEfmt ")
        u32(16); u16(1); u16(1); u32(UInt32(rate)); u32(UInt32(rate * 2)); u16(2); u16(16)
        text("data"); u32(UInt32(samples * 2))
        for frame in 0..<samples {
            let time = Double(frame) / Double(rate)
            let beat = Int(time)
            let local = time - Double(beat)
            let length = beat == 0 ? 0.22 : 0.13
            let frequency = beat == 0 ? 1200.0 : 900.0
            let envelope = local < length ? min(1, local / 0.006) * min(1, (length - local) / 0.02) : 0
            let sample = Int16(sin(2 * .pi * frequency * local) * envelope * 20000)
            u16(UInt16(bitPattern: sample))
        }
        return data
    }
    func pause() {
        skipPlayer?.stop()
        player?.pause()
        speech.stopSpeaking(at: .immediate)
    }
    func say(_ text: String) {
        guard mode == .voice else { return }
        speech.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        utterance.rate = 0.5
        utterance.volume = 0.9
        speech.speak(utterance)
    }
    func stop() {
        skipPlayer?.stop()
        skipPlayer = nil
        player?.stop()
        player = nil
        speech.stopSpeaking(at: .immediate)
        if let trackURL { try? FileManager.default.removeItem(at: trackURL) }
        trackURL = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private struct Tone {
        let start: Double
        let length: Double
        let frequency: Double
    }
    private static func makeTrack(phases: [WorkoutPhase], countdownSeconds: Int) throws -> URL {
        var tones: [Tone] = []
        var elapsed = 0
        for phase in phases {
            tones.append(Tone(start: Double(elapsed), length: 0.28,
                              frequency: phase.kind == .work ? 1100 : 700))
            for seconds in CountdownSchedule.seconds(duration: phase.duration, lead: countdownSeconds) {
                tones.append(Tone(start: Double(elapsed + phase.duration - seconds),
                                  length: 0.10, frequency: 850))
            }
            elapsed += phase.duration
        }
        tones.append(Tone(start: Double(elapsed), length: 0.50, frequency: 1400))
        tones.sort { $0.start < $1.start }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("interval-\(UUID().uuidString).wav")
        do {
            let sampleRate = 8000.0
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ]
            let file = try AVAudioFile(forWriting: url, settings: settings)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: 4096),
                  let channel = buffer.floatChannelData?[0] else {
                throw NSError(domain: "Interval.Audio", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "Cannot prepare audio."])
            }
            let totalFrames = Int((Double(elapsed) + 0.6) * sampleRate)
            var frame = 0
            var toneIndex = 0
            while frame < totalFrames {
                let count = min(4096, totalFrames - frame)
                buffer.frameLength = AVAudioFrameCount(count)
                for offset in 0..<count {
                    let time = Double(frame + offset) / sampleRate
                    while toneIndex + 1 < tones.count && time >= tones[toneIndex + 1].start {
                        toneIndex += 1
                    }
                    let tone = tones[toneIndex]
                    let local = time - tone.start
                    if local >= 0 && local < tone.length {
                        let envelope = min(1, local / 0.01) * min(1, (tone.length - local) / 0.025)
                        channel[offset] = Float(sin(2 * .pi * tone.frequency * local) * envelope * 0.6)
                    } else {
                        channel[offset] = 0
                    }
                }
                try file.write(from: buffer)
                frame += count
            }
            return url
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw error
        }
    }
}
