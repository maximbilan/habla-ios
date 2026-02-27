import Foundation

actor AgentWebSocketService {
    private var webSocketTask: URLSessionWebSocketTask?
    private var isConnected: Bool = false

    func connect(callSid: String, serverURL: String) async throws {
        let wsURL = serverURL
            .replacingOccurrences(of: "http://", with: "ws://")
            .replacingOccurrences(of: "https://", with: "wss://")

        guard let url = URL(string: "\(wsURL)/agent/ws/\(callSid)") else {
            throw AppError.webSocketError("Invalid Agent WebSocket URL")
        }

        var request = URLRequest(url: url)
        BackendRequestAuth.apply(to: &request)
        BackendRequestContext.apply(to: &request)

        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        isConnected = true
    }

    func disconnect() async {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
    }

    func sendInstruction(_ text: String) async throws {
        try await sendJSON(["type": "instruction", "text": text])
    }

    func sendEndConversation(_ text: String) async throws {
        try await sendJSON(["type": "end_conversation", "text": text])
    }

    func receiveLoop(onMessage: @escaping @Sendable (AgentWSMessage) -> Void) async {
        guard let webSocketTask else { return }

        while !Task.isCancelled && isConnected {
            do {
                let message = try await webSocketTask.receive()
                switch message {
                case .string(let text):
                    if let parsed = AgentWSMessage.decode(from: text) {
                        onMessage(parsed)
                    }
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8),
                       let parsed = AgentWSMessage.decode(from: text) {
                        onMessage(parsed)
                    }
                @unknown default:
                    break
                }
            } catch {
                if !Task.isCancelled {
                    isConnected = false
                }
                break
            }
        }
    }

    private func sendJSON(_ payload: [String: String]) async throws {
        guard let webSocketTask, isConnected else {
            throw AppError.webSocketError("Agent WebSocket not connected")
        }

        let data = try JSONSerialization.data(withJSONObject: payload)
        guard let text = String(data: data, encoding: .utf8) else {
            throw AppError.webSocketError("Failed to encode Agent WebSocket payload")
        }
        try await webSocketTask.send(.string(text))
    }
}
