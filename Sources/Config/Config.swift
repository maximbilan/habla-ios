import Foundation

// Auto-generated. Do not edit.
enum AppConfig {
    static let backendURL = ""
    static let backendURLNova = ""
    static let backendURLGemini = ""
    static let backendAuthToken = ""
}

enum BackendRequestAuth {
    static var token: String {
        AppConfig.backendAuthToken.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func apply(to request: inout URLRequest) {
        guard !token.isEmpty else {
            return
        }
        request.setValue(token, forHTTPHeaderField: "Authorization")
    }
}
