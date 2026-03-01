//
//  WebSocketMiddleware.swift
//  habla-ios
//

import Foundation

final class WebSocketMiddleware: Middleware, @unchecked Sendable {
    private let webSocketService: WebSocketService
    private let audioService: AudioService
    private let conversationBuffer: CallConversationBuffer
    private var remoteActivityResetTask: Task<Void, Never>?
    private var didMarkConnectedFromAudio = false

    init(
        webSocketService: WebSocketService = WebSocketService(),
        audioService: AudioService = AudioService(),
        conversationBuffer: CallConversationBuffer = CallConversationBuffer()
    ) {
        self.webSocketService = webSocketService
        self.audioService = audioService
        self.conversationBuffer = conversationBuffer
    }

    func process(action: AppAction, state: AppState, dispatch: @escaping @MainActor (AppAction) -> Void) {
        switch action {
        case .connectWebSocket(let callSid):
            didMarkConnectedFromAudio = false
            remoteActivityResetTask?.cancel()
            remoteActivityResetTask = nil
            conversationBuffer.reset()
            let serverURL = state.serverURL
            let ws = webSocketService
            let audio = audioService

            Task {
                do {
                    try await ws.connect(callSid: callSid, serverURL: serverURL)

                    await ws.receiveLoop(onAudio: { data in
                        Task {
                            if !self.didMarkConnectedFromAudio {
                                self.didMarkConnectedFromAudio = true
                                await MainActor.run {
                                    dispatch(.callStatusUpdated(.connected))
                                }
                            }

                            await audio.playAudio(data)
                            await MainActor.run {
                                dispatch(.receivingAudioChanged(true))
                            }
                            self.remoteActivityResetTask?.cancel()
                            self.remoteActivityResetTask = Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 300_000_000)
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

                    remoteActivityResetTask?.cancel()
                    remoteActivityResetTask = nil
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
            remoteActivityResetTask?.cancel()
            remoteActivityResetTask = nil
            Task {
                await webSocketService.disconnect()
            }

        case .callFailed:
            remoteActivityResetTask?.cancel()
            remoteActivityResetTask = nil
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
        case .status(let status):
            let mappedStatus = mapCallStatus(status)
            dispatch(.callStatusUpdated(mappedStatus))
            if mappedStatus == .connected {
                didMarkConnectedFromAudio = true
            }
        case .criticalConfirmation(let confirmation):
            dispatch(.criticalConfirmationReceived(confirmation))
        case .verifiedFactsSummary(let facts):
            dispatch(.verifiedFactsSummaryReceived(facts))
        case .translation(let text):
            conversationBuffer.append(role: .interpreter, text: text)
        case .transcription(let text):
            conversationBuffer.append(role: .caller, text: text)
        case .error(let text):
            dispatch(.callFailed(.webSocketError(text)))
        case .interrupted:
            dispatch(.receivingAudioChanged(false))
        }
    }

    private func mapCallStatus(_ raw: String) -> CallStatus {
        switch raw.lowercased() {
        case "initiating":
            return .initiating
        case "connecting":
            return .connecting
        case "ringing":
            return .ringing
        case "connected", "in_progress", "in-progress":
            return .connected
        case "ended", "completed":
            return .ended
        case "failed":
            return .failed("Call failed")
        default:
            return .connecting
        }
    }
}
