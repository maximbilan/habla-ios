import Foundation

struct CallerMemory: Codable, Equatable, Sendable, Identifiable {
    let phoneKey: String
    let phoneNumber: String
    var consentGranted: Bool
    var preferredTargetLanguage: String?
    var preferredTone: CallerTone
    var priorIssues: String
    var callCount: Int
    var lastCallAt: Date?
    var updatedAt: Date

    var id: String { phoneKey }
}

struct CallerMemoryDraft: Equatable, Sendable {
    let phoneNumber: String
    let consentGranted: Bool
    let preferredTargetLanguage: String?
    let preferredTone: CallerTone
    let priorIssues: String
}

enum CallerTone: String, CaseIterable, Codable, Equatable, Sendable, Identifiable {
    case neutral
    case friendly
    case formal
    case direct
    case empathetic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .neutral:
            return "Neutral"
        case .friendly:
            return "Friendly"
        case .formal:
            return "Formal"
        case .direct:
            return "Direct"
        case .empathetic:
            return "Empathetic"
        }
    }

    var agentInstruction: String {
        switch self {
        case .neutral:
            return "neutral and concise"
        case .friendly:
            return "friendly and warm"
        case .formal:
            return "formal and professional"
        case .direct:
            return "direct and efficient"
        case .empathetic:
            return "empathetic and reassuring"
        }
    }
}

enum CallerMemoryKey {
    static func normalize(phoneNumber: String) -> String? {
        let trimmed = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let digits = trimmed.filter(\.isNumber)
        guard digits.count >= 6 else { return nil }

        return "+\(digits)"
    }
}
