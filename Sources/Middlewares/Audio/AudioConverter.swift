//
//  AudioConverter.swift
//  habla-ios
//

@preconcurrency import AVFoundation

enum AudioConstants {
    static let sampleRate: Double = 16000
    static let channels: AVAudioChannelCount = 1
    static let bytesPerFrame: UInt32 = 2
    static let frameDuration: Double = 0.02

    static var pcmFormat: AVAudioFormat {
        AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: sampleRate,
            channels: channels,
            interleaved: true
        )!
    }
}

private final class ConversionState: @unchecked Sendable {
    var consumed = false
}

enum AudioConverter {
    static func pcmBufferToData(_ buffer: AVAudioPCMBuffer) -> Data? {
        guard let int16Data = buffer.int16ChannelData else { return nil }
        let frameCount = Int(buffer.frameLength)
        let byteCount = frameCount * Int(AudioConstants.bytesPerFrame)
        return Data(bytes: int16Data[0], count: byteCount)
    }

    static func dataToPCMBuffer(_ data: Data) -> AVAudioPCMBuffer? {
        let format = AudioConstants.pcmFormat
        let frameCount = UInt32(data.count) / AudioConstants.bytesPerFrame

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        guard let channelData = buffer.int16ChannelData else { return nil }

        data.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return }
            channelData[0].update(from: baseAddress.assumingMemoryBound(to: Int16.self), count: Int(frameCount))
        }

        return buffer
    }

    static func calculateRMS(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.int16ChannelData else { return 0 }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return 0 }

        var sum: Float = 0
        let data = channelData[0]
        for i in 0..<frameCount {
            let sample = Float(data[i]) / Float(Int16.max)
            sum += sample * sample
        }

        let rms = sqrt(sum / Float(frameCount))
        return min(rms * 3.0, 1.0)
    }

    static func convert(
        buffer: AVAudioPCMBuffer,
        from sourceFormat: AVAudioFormat,
        to destinationFormat: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        guard let converter = AVAudioConverter(from: sourceFormat, to: destinationFormat) else {
            return nil
        }

        let ratio = destinationFormat.sampleRate / sourceFormat.sampleRate
        let outputFrameCount = UInt32(Double(buffer.frameLength) * ratio)

        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: destinationFormat,
            frameCapacity: outputFrameCount
        ) else {
            return nil
        }

        var error: NSError?
        let inputBuffer = buffer
        let state = ConversionState()

        converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if !state.consumed {
                state.consumed = true
                outStatus.pointee = .haveData
                return inputBuffer
            }
            outStatus.pointee = .noDataNow
            return nil
        }

        if error != nil {
            return nil
        }

        return outputBuffer
    }
}
