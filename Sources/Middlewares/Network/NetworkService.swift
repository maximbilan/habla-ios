//
//  NetworkService.swift
//  habla-ios
//

import Foundation

actor NetworkService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func initiateCall(
        to phoneNumber: String,
        from: String?,
        sourceLanguage: String,
        targetLanguage: String,
        serverURL: String
    ) async throws -> CallResponse {
        guard let url = URL(string: "\(serverURL)/call") else {
            throw AppError.networkError("Invalid server URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            CallRequest(
                to: phoneNumber,
                from: from,
                source_language: sourceLanguage,
                target_language: targetLanguage
            )
        )
        request.timeoutInterval = 30

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AppError.networkError("Server error (\(httpResponse.statusCode)): \(body)")
        }

        return try JSONDecoder().decode(CallResponse.self, from: data)
    }

    func endCall(callSid: String, serverURL: String) async throws {
        guard let url = URL(string: "\(serverURL)/call/\(callSid)/end") else {
            throw AppError.networkError("Invalid server URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AppError.networkError("Failed to end call (\(httpResponse.statusCode)): \(body)")
        }
    }

    func getCallStatus(callSid: String, serverURL: String) async throws -> CallStatusResponse {
        guard let url = URL(string: "\(serverURL)/call/\(callSid)/status") else {
            throw AppError.networkError("Invalid server URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AppError.networkError("Status check failed (\(httpResponse.statusCode)): \(body)")
        }

        return try JSONDecoder().decode(CallStatusResponse.self, from: data)
    }
}
