import Foundation

actor CallerIdService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func startVerification(
        phoneNumber: String,
        friendlyName: String?,
        serverURL: String
    ) async throws -> CallerIdVerifyResponse {
        guard let url = URL(string: "\(serverURL)/caller-id/verify/start") else {
            throw AppError.networkError("Invalid server URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        BackendRequestAuth.apply(to: &request)
        BackendRequestContext.apply(to: &request)
        request.timeoutInterval = 30

        let payload = CallerIdStartVerifyRequest(
            phoneNumber: phoneNumber,
            friendlyName: friendlyName?.nilIfEmpty
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        try validateHTTPResponse(
            response,
            data: data,
            fallback: "Server error"
        )
        return try JSONDecoder().decode(CallerIdVerifyResponse.self, from: data)
    }

    func checkStatus(phoneNumber: String, serverURL: String) async throws -> CallerIdStatusResponse {
        let escaped = phoneNumber.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? phoneNumber
        guard let url = URL(string: "\(serverURL)/caller-id/verify/status/\(escaped)") else {
            throw AppError.networkError("Invalid server URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        BackendRequestAuth.apply(to: &request)
        BackendRequestContext.apply(to: &request)
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)
        try validateHTTPResponse(
            response,
            data: data,
            fallback: "Status check failed"
        )
        return try JSONDecoder().decode(CallerIdStatusResponse.self, from: data)
    }

    func listVerified(serverURL: String) async throws -> CallerIdListResponse {
        guard let url = URL(string: "\(serverURL)/caller-id/list") else {
            throw AppError.networkError("Invalid server URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        BackendRequestAuth.apply(to: &request)
        BackendRequestContext.apply(to: &request)
        request.timeoutInterval = 20

        let (data, response) = try await session.data(for: request)
        try validateHTTPResponse(
            response,
            data: data,
            fallback: "Failed to load caller IDs"
        )
        return try JSONDecoder().decode(CallerIdListResponse.self, from: data)
    }

    func delete(sid: String, serverURL: String) async throws {
        guard let url = URL(string: "\(serverURL)/caller-id/\(sid)") else {
            throw AppError.networkError("Invalid server URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        BackendRequestAuth.apply(to: &request)
        BackendRequestContext.apply(to: &request)
        request.timeoutInterval = 20

        let (data, response) = try await session.data(for: request)
        try validateHTTPResponse(
            response,
            data: data,
            fallback: "Failed to delete caller ID"
        )
    }

    private func validateHTTPResponse(_ response: URLResponse, data: Data, fallback: String) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = serverErrorMessage(
                statusCode: httpResponse.statusCode,
                data: data,
                fallback: fallback
            )
            throw AppError.networkError(message)
        }
    }

    private func serverErrorMessage(statusCode: Int, data: Data, fallback: String) -> String {
        if let parsed = parseServerError(data: data) {
            return "\(parsed) (\(statusCode))"
        }
        return "\(fallback) (\(statusCode))"
    }

    private func parseServerError(data: Data) -> String? {
        guard !data.isEmpty else { return nil }

        if let decoded = try? JSONDecoder().decode(CallerIdServerErrorPayload.self, from: data) {
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
}

private struct CallerIdStartVerifyRequest: Codable, Sendable {
    let phoneNumber: String
    let friendlyName: String?

    enum CodingKeys: String, CodingKey {
        case phoneNumber = "phone_number"
        case friendlyName = "friendly_name"
    }
}

private struct CallerIdServerErrorPayload: Decodable {
    let detail: String?
    let message: String?
    let error: String?
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
