import AVFoundation

/// Generates a pure sine-wave tone at a given frequency using an AVAudioSourceNode.
/// No files, no assets — just math, so it's cheap and reliable in CI-built apps.
final class ToneGenerator {
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var phase: Double = 0

    /// Starts playing a sine tone. Call `stop()` to end it (or use `playFor`).
    func start(frequency: Double = 15000, amplitude: Double = 0.5) {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)

        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        let phaseIncrement = (2.0 * Double.pi * frequency) / sampleRate

        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let sampleVal = Float(sin(self.phase)) * Float(amplitude)
                self.phase += phaseIncrement
                if self.phase > 2.0 * Double.pi { self.phase -= 2.0 * Double.pi }
                for buffer in ablPointer {
                    let buf = UnsafeMutableBufferPointer<Float>(buffer)
                    buf[frame] = sampleVal
                }
            }
            return noErr
        }

        sourceNode = node
        let format = engine.outputNode.inputFormat(forBus: 0)
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
        } catch {
            print("ToneGenerator failed to start engine: \(error)")
        }
    }

    func stop() {
        engine.stop()
        if let sourceNode {
            engine.detach(sourceNode)
        }
        sourceNode = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Convenience: plays for a fixed duration then stops and calls completion.
    func playFor(seconds: Double, frequency: Double = 15000, completion: @escaping () -> Void) {
        start(frequency: frequency)
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            self?.stop()
            completion()
        }
    }
}
