//
//  WebSocketService.swift
//  habla-ios
//

import Foundation

actor WebSocketService {
    private var webSocketTask: URLSessionWebSocketTask?
    private var isConnected: Bool = false

    func connect(callSid: String, serverURL: String) async throws {
        let wsURL = serverURL
            .replacingOccurrences(of: "http://", with: "ws://")
            .replacingOccurrences(of: "https://", with: "wss://")

        guard let url = URL(string: "\(wsURL)/ws/\(callSid)") else {
            throw AppError.webSocketError("Invalid WebSocket URL")
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

    func sendAudio(_ data: Data) async throws {
        guard let webSocketTask, isConnected else {
            throw AppError.webSocketError("WebSocket not connected")
        }
        try await webSocketTask.send(.data(data))
    }

    func receiveLoop(onAudio: @escaping @Sendable (Data) -> Void) async {
        guard let webSocketTask else { return }

        while !Task.isCancelled && isConnected {
            do {
                let message = try await webSocketTask.receive()
                switch message {
                case .data(let data):
                    onAudio(data)
                case .string:
                    break
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
}
