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
        request.timeoutInterval = 30

        let payload = CallerIdStartVerifyRequest(
            phoneNumber: phoneNumber,
            friendlyName: friendlyName?.nilIfEmpty
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        try validateHTTPResponse(response)
        return try JSONDecoder().decode(CallerIdVerifyResponse.self, from: data)
    }

    func checkStatus(phoneNumber: String, serverURL: String) async throws -> CallerIdStatusResponse {
        let escaped = phoneNumber.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? phoneNumber
        guard let url = URL(string: "\(serverURL)/caller-id/verify/status/\(escaped)") else {
            throw AppError.networkError("Invalid server URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)
        try validateHTTPResponse(response)
        return try JSONDecoder().decode(CallerIdStatusResponse.self, from: data)
    }

    func listVerified(serverURL: String) async throws -> CallerIdListResponse {
        guard let url = URL(string: "\(serverURL)/caller-id/list") else {
            throw AppError.networkError("Invalid server URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20

        let (data, response) = try await session.data(for: request)
        try validateHTTPResponse(response)
        return try JSONDecoder().decode(CallerIdListResponse.self, from: data)
    }

    func delete(sid: String, serverURL: String) async throws {
        guard let url = URL(string: "\(serverURL)/caller-id/\(sid)") else {
            throw AppError.networkError("Invalid server URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.timeoutInterval = 20

        let (_, response) = try await session.data(for: request)
        try validateHTTPResponse(response)
    }

    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.networkError("Server error (\(httpResponse.statusCode))")
        }
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

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
