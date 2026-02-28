import Foundation

final class AgentWebSocketMiddleware: Middleware, @unchecked Sendable {
    private let webSocketService: AgentWebSocketService
    private var entryIDsByKey: [String: UUID] = [:]
    private let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private let iso8601WithoutFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    init(webSocketService: AgentWebSocketService = AgentWebSocketService()) {
        self.webSocketService = webSocketService
    }

    func process(action: AppAction, state: AppState, dispatch: @escaping @MainActor (AppAction) -> Void) {
        switch action {
        case .connectAgentWebSocket(let callSid):
            entryIDsByKey.removeAll()
            let serverURL = state.serverURL
            let ws = webSocketService

            Task {
                do {
                    try await ws.connect(callSid: callSid, serverURL: serverURL)

                    await ws.receiveLoop { [weak self] message in
                        guard let self else { return }
                        Task { @MainActor in
                            self.handleMessage(message, dispatch: dispatch)
                        }
                    }
                } catch {
                    let appError = (error as? AppError) ?? .webSocketError(error.localizedDescription)
                    await MainActor.run {
                        dispatch(.agentWebSocketError(appError))
                    }
                }
            }

        case .sendAgentInstruction(let text):
            let ws = webSocketService
            Task {
                do {
                    try await ws.sendInstruction(text)
                    await MainActor.run {
                        dispatch(.agentInstructionSent)
                    }
                } catch {
                    let appError = (error as? AppError) ?? .webSocketError(error.localizedDescription)
                    await MainActor.run {
                        dispatch(.agentWebSocketError(appError))
                    }
                }
            }

        case .endAgentConversation(let text):
            let ws = webSocketService
            Task {
                do {
                    try await ws.sendEndConversation(text)
                } catch {
                    let appError = (error as? AppError) ?? .webSocketError(error.localizedDescription)
                    await MainActor.run {
                        dispatch(.agentWebSocketError(appError))
                    }
                }
            }

        case .endAgentCall, .agentCallFailed:
            let ws = webSocketService
            Task {
                await ws.disconnect()
            }

        default:
            break
        }
    }

    @MainActor
    private func handleMessage(_ message: AgentWSMessage, dispatch: @escaping @MainActor (AppAction) -> Void) {
        switch message {
        case .status(let status):
            dispatch(.callStatusUpdated(mapCallStatus(status)))
            if status == "ended" {
                dispatch(.endAgentCall)
            }

        case .agentStatus(let status):
            dispatch(.agentStatusUpdated(mapAgentStatus(status)))

        case .transcript(let role, let textOriginal, let textEn, let timestamp):
            let entry = makeEntry(role: role, textOriginal: textOriginal, textEn: textEn, timestamp: timestamp)
            dispatch(.agentTranscriptReceived(entry))

        case .transcriptUpdate(let role, let textOriginal, let textEn, let timestamp):
            let entry = makeEntry(role: role, textOriginal: textOriginal, textEn: textEn, timestamp: timestamp)
            dispatch(.agentTranscriptUpdated(entry))

        case .criticalConfirmation(let confirmation):
            dispatch(.criticalConfirmationReceived(confirmation))

        case .verifiedFactsSummary(let facts):
            dispatch(.verifiedFactsSummaryReceived(facts))
        }
    }

    @MainActor
    private func makeEntry(role: String, textOriginal: String, textEn: String?, timestamp: String) -> TranscriptEntry {
        let roleValue = TranscriptRole(rawValue: role) ?? .callee
        let normalizedText = textOriginal.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let key = "\(role)|\(timestamp)|\(normalizedText)"
        let id = entryIDsByKey[key] ?? {
            let newID = UUID()
            entryIDsByKey[key] = newID
            return newID
        }()

        return TranscriptEntry(
            id: id,
            role: roleValue,
            textOriginal: textOriginal,
            textEn: textEn,
            timestamp: parseDate(timestamp)
        )
    }

    private func mapCallStatus(_ raw: String) -> CallStatus {
        switch raw.lowercased() {
        case "initiating":
            return .initiating
        case "connecting":
            return .connecting
        case "ringing":
            return .ringing
        case "connected", "in_progress":
            return .connected
        case "ended", "completed":
            return .ended
        case "failed":
            return .failed("Call failed")
        default:
            return .connecting
        }
    }

    private func mapAgentStatus(_ raw: String) -> AgentStatus {
        switch raw.lowercased() {
        case "listening":
            return .listening
        case "speaking":
            return .speaking
        case "thinking":
            return .thinking
        default:
            return .idle
        }
    }

    private func parseDate(_ value: String) -> Date {
        if let parsed = iso8601WithFractionalSeconds.date(from: value) {
            return parsed
        }
        if let parsed = iso8601WithoutFractionalSeconds.date(from: value) {
            return parsed
        }
        return Date()
    }
}
