//
//  AudioService.swift
//  habla-ios
//

import AVFoundation

actor AudioService {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var isCapturing: Bool = false
    private var isMuted: Bool = false
    private var progressToneTask: Task<Void, Never>?

    func configureSession(useSpeaker: Bool) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetoothHFP, .defaultToSpeaker])
        try session.setPreferredSampleRate(AudioConstants.sampleRate)
        try session.setPreferredIOBufferDuration(AudioConstants.frameDuration)
        try session.overrideOutputAudioPort(useSpeaker ? .speaker : .none)
        try session.setActive(true)
    }

    func startCapture(
        onAudioCaptured: @escaping @Sendable (Data) -> Void,
        onLevelUpdate: @escaping @Sendable (Float) -> Void
    ) throws {
        guard !isCapturing else { return }

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()

        engine.attach(player)

        let outputFormat = AudioConstants.pcmFormat
        engine.connect(player, to: engine.mainMixerNode, format: outputFormat)

        let inputNode = engine.inputNode
        let hardwareFormat = inputNode.outputFormat(forBus: 0)
        let needsConversion = hardwareFormat.sampleRate != AudioConstants.sampleRate

        let tapFormat: AVAudioFormat
        if needsConversion {
            tapFormat = hardwareFormat
        } else {
            tapFormat = AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: AudioConstants.sampleRate,
                channels: 1,
                interleaved: true
            )!
        }

        let targetFormat = AudioConstants.pcmFormat
        let muted = UnsafeMutablePointer<Bool>.allocate(capacity: 1)
        muted.pointee = self.isMuted

        inputNode.installTap(onBus: 0, bufferSize: 640, format: tapFormat) { buffer, _ in
            let processBuffer: AVAudioPCMBuffer

            if needsConversion {
                guard let converted = AudioConverter.convert(
                    buffer: buffer,
                    from: tapFormat,
                    to: targetFormat
                ) else { return }
                processBuffer = converted
            } else {
                processBuffer = buffer
            }

            let level = AudioConverter.calculateRMS(buffer: processBuffer)
            onLevelUpdate(level)

            if !muted.pointee {
                if let data = AudioConverter.pcmBufferToData(processBuffer) {
                    onAudioCaptured(data)
                }
            }
        }

        try engine.start()
        player.play()

        self.audioEngine = engine
        self.playerNode = player
        self.isCapturing = true
    }

    func stopCapture() {
        stopProgressTone(resetPlayer: true)
        audioEngine?.inputNode.removeTap(onBus: 0)
        playerNode?.stop()
        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil
        isCapturing = false
    }

    func playAudio(_ data: Data) {
        guard let playerNode, let audioEngine, audioEngine.isRunning else { return }
        guard let buffer = AudioConverter.dataToPCMBuffer(data) else { return }

        playerNode.scheduleBuffer(buffer, completionHandler: nil)

        if !playerNode.isPlaying {
            playerNode.play()
        }
    }

    func setMuted(_ muted: Bool) {
        self.isMuted = muted
    }

    func setSpeaker(_ speaker: Bool) throws {
        let session = AVAudioSession.sharedInstance()
        try session.overrideOutputAudioPort(speaker ? .speaker : .none)
    }

    func startProgressTone() {
        guard isCapturing else { return }
        guard progressToneTask == nil else { return }

        let toneData = Self.progressTonePCMData
        progressToneTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.playToneChunk(toneData)
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    func stopProgressTone(resetPlayer: Bool = false) {
        progressToneTask?.cancel()
        progressToneTask = nil
        if resetPlayer {
            playerNode?.stop()
        }
    }

    private func playToneChunk(_ data: Data) {
        guard let playerNode, let audioEngine, audioEngine.isRunning else { return }
        guard let buffer = AudioConverter.dataToPCMBuffer(data) else { return }
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }

    private static let progressTonePCMData: Data = {
        let durationSeconds = 0.35
        let sampleRate = AudioConstants.sampleRate
        let frameCount = Int(sampleRate * durationSeconds)
        let fadeSamples = Int(sampleRate * 0.015)
        let amplitude = 0.18
        let lowFrequency = 425.0
        let highFrequency = 480.0

        var samples = [Int16](repeating: 0, count: frameCount)
        for index in 0..<frameCount {
            let time = Double(index) / sampleRate
            let mixed = (sin(2 * .pi * lowFrequency * time) + sin(2 * .pi * highFrequency * time)) * 0.5

            let fadeIn = min(1.0, Double(index) / Double(max(1, fadeSamples)))
            let fadeOut = min(1.0, Double(frameCount - index) / Double(max(1, fadeSamples)))
            let envelope = min(fadeIn, fadeOut)

            let value = mixed * amplitude * envelope
            let scaled = value * Double(Int16.max)
            samples[index] = Int16(max(Double(Int16.min), min(Double(Int16.max), scaled)))
        }

        return samples.withUnsafeBufferPointer { Data(buffer: $0) }
    }()
}
