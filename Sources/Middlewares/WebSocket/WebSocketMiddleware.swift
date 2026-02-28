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
                        dispatch(.callStatusUpdated(.connected))
                    }

                    await ws.receiveLoop(onAudio: { data in
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
                    }, onMessage: { [weak self] message in
                        guard let self else { return }
                        Task { @MainActor in
                            self.handleMessage(message, dispatch: dispatch)
                        }
                    }
                    )

                    await MainActor.run {
                        dispatch(.callEnded)
                    }
                } catch {
                    let appError = (error as? AppError) ?? .webSocketError(error.localizedDescription)
                    await MainActor.run {
                        dispatch(.callFailed(appError))
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

    @MainActor
    private func handleMessage(
        _ message: TranslationWSMessage,
        dispatch: @escaping @MainActor (AppAction) -> Void
    ) {
        switch message {
        case .criticalConfirmation(let confirmation):
            dispatch(.criticalConfirmationReceived(confirmation))
        case .verifiedFactsSummary(let facts):
            dispatch(.verifiedFactsSummaryReceived(facts))
        case .translation(let text):
            dispatch(
                .callConversationTurnReceived(
                    ConversationTurn(role: .interpreter, text: text, timestamp: Date())
                )
            )
        case .transcription(let text):
            dispatch(
                .callConversationTurnReceived(
                    ConversationTurn(role: .caller, text: text, timestamp: Date())
                )
            )
        case .error(let text):
            dispatch(.callFailed(.webSocketError(text)))
        case .status, .interrupted:
            break
        }
    }
}
