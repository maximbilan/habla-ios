import Foundation

// Auto-generated. Do not edit.
enum AppConfig {
    static let backendURL = "https://habla-core-gemini-2reqhjnjja-uc.a.run.app"
    static let backendURLNova = "https://44-211-73-87.sslip.io"
    static let backendURLGemini = "https://habla-core-gemini-2reqhjnjja-uc.a.run.app"
    static let backendAuthToken = "f86a00be1f7065f32547a86a0fb7e0d0377a8f6f573df48ab0b97bf225cebc82"
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
