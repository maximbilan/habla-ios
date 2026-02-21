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
        BackendRequestAuth.apply(to: &request)
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
        let httpResponse = try validatedHTTPResponse(response)

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.networkError(serverErrorMessage(statusCode: httpResponse.statusCode, fallback: "Server error"))
        }

        return try JSONDecoder().decode(CallResponse.self, from: data)
    }

    func endCall(callSid: String, serverURL: String) async throws {
        guard let url = URL(string: "\(serverURL)/call/\(callSid)/end") else {
            throw AppError.networkError("Invalid server URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        BackendRequestAuth.apply(to: &request)
        request.timeoutInterval = 15

        let (_, response) = try await session.data(for: request)
        let httpResponse = try validatedHTTPResponse(response)

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.networkError(serverErrorMessage(statusCode: httpResponse.statusCode, fallback: "Failed to end call"))
        }
    }

    func getCallStatus(callSid: String, serverURL: String) async throws -> CallStatusResponse {
        guard let url = URL(string: "\(serverURL)/call/\(callSid)/status") else {
            throw AppError.networkError("Invalid server URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        BackendRequestAuth.apply(to: &request)
        request.timeoutInterval = 10

        let (data, response) = try await session.data(for: request)
        let httpResponse = try validatedHTTPResponse(response)

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.networkError(serverErrorMessage(statusCode: httpResponse.statusCode, fallback: "Status check failed"))
        }

        return try JSONDecoder().decode(CallStatusResponse.self, from: data)
    }

    private func validatedHTTPResponse(_ response: URLResponse) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError("Invalid response")
        }
        return httpResponse
    }

    private func serverErrorMessage(statusCode: Int, fallback: String) -> String {
        "\(fallback) (\(statusCode))"
    }
}
