import Foundation

actor AgentNetworkService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func initiateAgentCall(
        to phoneNumber: String,
        from: String?,
        prompt: String,
        userName: String,
        language: String,
        voiceGender: VoiceGender,
        serverURL: String
    ) async throws -> AgentCallResponse {
        guard let url = URL(string: "\(serverURL)/agent/call") else {
            throw AppError.networkError("Invalid server URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        BackendRequestAuth.apply(to: &request)
        BackendRequestContext.apply(to: &request)
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder().encode(
            AgentCallRequest(
                to: phoneNumber,
                from: from,
                prompt: prompt,
                user_name: userName,
                language: language,
                voice_gender: voiceGender
            )
        )

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

        return try JSONDecoder().decode(AgentCallResponse.self, from: data)
    }

    func endAgentCall(callSid: String, serverURL: String) async throws {
        guard let url = URL(string: "\(serverURL)/agent/call/\(callSid)/end") else {
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
                    fallback: "Failed to end agent call"
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

        if let decoded = try? JSONDecoder().decode(AgentServerErrorPayload.self, from: data) {
            if let detail = trimmedNonEmpty(decoded.detail) {
                return detail
            }
            if let message = trimmedNonEmpty(decoded.message) {
                return message
            }
            if let error = trimmedNonEmpty(decoded.error) {
                return error
            }
        }

        if let raw = trimmedNonEmpty(String(data: data, encoding: .utf8)) {
            return raw
        }

        return nil
    }

    private func trimmedNonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
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

private struct AgentServerErrorPayload: Decodable {
    let detail: String?
    let message: String?
    let error: String?
}
