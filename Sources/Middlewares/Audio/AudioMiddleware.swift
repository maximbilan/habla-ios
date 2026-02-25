//
//  AudioMiddleware.swift
//  habla-ios
//

import AVFoundation

final class AudioMiddleware: Middleware, @unchecked Sendable {
    private let audioService: AudioService
    private let webSocketService: WebSocketService

    init(audioService: AudioService, webSocketService: WebSocketService) {
        self.audioService = audioService
        self.webSocketService = webSocketService
    }

    func process(action: AppAction, state: AppState, dispatch: @escaping @MainActor (AppAction) -> Void) {
        switch action {
        case .startAudioCapture:
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
                } catch {
                    let appError = (error as? AppError) ?? .audioError(error.localizedDescription)
                    await MainActor.run {
                        dispatch(.callFailed(appError))
                    }
                }
            }

        case .endCall, .callFailed, .callEnded:
            Task {
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
