//
//  AudioMiddleware.swift
//  habla-ios
//

import AVFoundation

final class AudioMiddleware: Middleware, @unchecked Sendable {
    private let audioService: AudioService
    private let webSocketService: WebSocketService
    private var hasRemotePresence = false

    init(audioService: AudioService, webSocketService: WebSocketService) {
        self.audioService = audioService
        self.webSocketService = webSocketService
    }

    func process(action: AppAction, state: AppState, dispatch: @escaping @MainActor (AppAction) -> Void) {
        switch action {
        case .startAudioCapture:
            hasRemotePresence = false
            let audio = audioService
            let ws = webSocketService

            Task {
                do {
                    let micPermission = await AVAudioApplication.requestRecordPermission()
                    guard micPermission else {
                        await MainActor.run {
                            dispatch(.callFailed(.microphonePermissionDenied))
                        }
                        return
                    }

                    try await audio.configureSession(useSpeaker: false)
                    try await audio.startCapture(
                        onAudioCaptured: { data in
                            Task {
                                try? await ws.sendAudio(data)
                            }
                        },
                        onLevelUpdate: { level in
                            Task { @MainActor in
                                dispatch(.inputAudioLevelUpdated(level))
                            }
                        }
                    )

                    await audio.startProgressTone()
                } catch {
                    let appError = (error as? AppError) ?? .audioError(error.localizedDescription)
                    await MainActor.run {
                        dispatch(.callFailed(appError))
                    }
                }
            }

        case .callStatusUpdated(.connected):
            guard !hasRemotePresence else { break }
            hasRemotePresence = true
            Task {
                await audioService.stopProgressTone(resetPlayer: false)
            }

        case .receivingAudioChanged(let receiving):
            guard receiving, !hasRemotePresence else { break }
            hasRemotePresence = true
            Task {
                await audioService.stopProgressTone(resetPlayer: true)
            }

        case .endCall, .callFailed, .callEnded:
            hasRemotePresence = false
            Task {
                await audioService.stopProgressTone(resetPlayer: true)
                await audioService.stopCapture()
            }

        case .toggleMute:
            let muted = !state.isMuted
            Task {
                await audioService.setMuted(muted)
            }

        case .toggleSpeaker:
            let speaker = !state.isSpeaker
            Task {
                try? await audioService.setSpeaker(speaker)
            }

        default:
            break
        }
    }
}
