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
        voiceGender: VoiceGender,
        serverURL: String
    ) async throws -> CallResponse {
        guard let url = URL(string: "\(serverURL)/call") else {
            throw AppError.networkError("Invalid server URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        BackendRequestAuth.apply(to: &request)
        BackendRequestContext.apply(to: &request)
        request.httpBody = try JSONEncoder().encode(
            CallRequest(
                to: phoneNumber,
                from: from,
                source_language: sourceLanguage,
                target_language: targetLanguage,
                voice_gender: voiceGender
            )
        )
        request.timeoutInterval = 30

        let (data, response) = try await session.data(for: request)
        let httpResponse = try validatedHTTPResponse(response)

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.networkError(
                serverErrorMessage(
                    statusCode: httpResponse.statusCode,
                    data: data,
                    fallback: "Server error"
                )
            )
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
        BackendRequestContext.apply(to: &request)
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)
        let httpResponse = try validatedHTTPResponse(response)

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.networkError(
                serverErrorMessage(
                    statusCode: httpResponse.statusCode,
                    data: data,
                    fallback: "Failed to end call"
                )
            )
        }
    }

    private func validatedHTTPResponse(_ response: URLResponse) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError("Invalid response")
        }
        return httpResponse
    }

    private func serverErrorMessage(statusCode: Int, data: Data, fallback: String) -> String {
        if let parsed = parseServerError(data: data) {
            if let unsupportedMessage = unsupportedDestinationMessage(for: parsed) {
                return unsupportedMessage
            }
            return "\(parsed) (\(statusCode))"
        }
        return "\(fallback) (\(statusCode))"
    }

    private func parseServerError(data: Data) -> String? {
        guard !data.isEmpty else { return nil }

        if let decoded = try? JSONDecoder().decode(ServerErrorPayload.self, from: data) {
            if let detail = decoded.detail?.trimmedNonEmpty {
                return detail
            }
            if let message = decoded.message?.trimmedNonEmpty {
                return message
            }
            if let error = decoded.error?.trimmedNonEmpty {
                return error
            }
        }

        if let raw = String(data: data, encoding: .utf8)?.trimmedNonEmpty {
            return raw
        }

        return nil
    }

    private func unsupportedDestinationMessage(for message: String) -> String? {
        let normalized = message.lowercased()
        if normalized.contains("account not authorized to call")
            || normalized.contains("international permissions")
            || normalized.contains("geo-permissions")
            || normalized.contains("twilio error code: 21215")
            || normalized.contains("unable to create record: account not authorized to call") {
            return "Calls to this destination aren't supported yet. Try another number."
        }
        return nil
    }
}

private struct ServerErrorPayload: Decodable {
    let detail: String?
    let message: String?
    let error: String?
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
