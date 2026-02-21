//
//  WebSocketMiddleware.swift
//  habla-ios
//

import Foundation

final class WebSocketMiddleware: Middleware, @unchecked Sendable {
    private let webSocketService: WebSocketService
    private let audioService: AudioService

    init(webSocketService: WebSocketService = WebSocketService(), audioService: AudioService = AudioService()) {
        self.webSocketService = webSocketService
        self.audioService = audioService
    }

    func process(action: AppAction, state: AppState, dispatch: @escaping @MainActor (AppAction) -> Void) {
        switch action {
        case .connectWebSocket(let callSid):
            let serverURL = state.serverURL
            let ws = webSocketService
            let audio = audioService

            Task {
                do {
                    try await ws.connect(callSid: callSid, serverURL: serverURL)
                    await MainActor.run {
                        dispatch(.webSocketConnected)
                        dispatch(.callStatusUpdated(.connected))
                    }

                    await ws.receiveLoop { data in
                        Task {
                            await audio.playAudio(data)
                            await MainActor.run {
                                dispatch(.receivingAudioChanged(true))
                            }
                            try? await Task.sleep(nanoseconds: 100_000_000)
                            await MainActor.run {
                                dispatch(.receivingAudioChanged(false))
                            }
                        }
                    }

                    await MainActor.run {
                        dispatch(.webSocketDisconnected)
                    }
                } catch {
                    let appError = (error as? AppError) ?? .webSocketError(error.localizedDescription)
                    await MainActor.run {
                        dispatch(.webSocketError(appError))
                    }
                }
            }

        case .endCall:
            Task {
                await webSocketService.disconnect()
            }

        case .callFailed:
            Task {
                await webSocketService.disconnect()
            }

        default:
            break
        }
    }
}
