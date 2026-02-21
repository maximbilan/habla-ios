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
        serverURL: String
    ) async throws -> AgentCallResponse {
        guard let url = URL(string: "\(serverURL)/agent/call") else {
            throw AppError.networkError("Invalid server URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder().encode(
            AgentCallRequest(
                to: phoneNumber,
                from: from,
                prompt: prompt,
                user_name: userName,
                language: language
            )
        )

        let (data, response) = try await session.data(for: request)
        let httpResponse = try validatedHTTPResponse(response)
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.networkError(serverErrorMessage(statusCode: httpResponse.statusCode, fallback: "Server error"))
        }

        return try JSONDecoder().decode(AgentCallResponse.self, from: data)
    }

    func endAgentCall(callSid: String, serverURL: String) async throws {
        guard let url = URL(string: "\(serverURL)/agent/call/\(callSid)/end") else {
            throw AppError.networkError("Invalid server URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15

        let (_, response) = try await session.data(for: request)
        let httpResponse = try validatedHTTPResponse(response)
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.networkError(serverErrorMessage(statusCode: httpResponse.statusCode, fallback: "Failed to end agent call"))
        }
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
