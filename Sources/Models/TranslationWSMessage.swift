import Foundation

enum TranslationWSMessage: Sendable {
    case status(String)
    case translation(String)
    case transcription(String)
    case interrupted
    case error(String)
    case criticalConfirmation(CriticalConfirmation)
    case verifiedFactsSummary([VerifiedFact])
}

private struct TranslationWSRawMessage: Decodable, Sendable {
    let type: String
    let status: String?
    let text: String?
    let message: String?
    let facts: [VerifiedFact]?
}

extension TranslationWSMessage {
    static func decode(from text: String) -> TranslationWSMessage? {
        guard let data = text.data(using: .utf8),
              let raw = try? JSONDecoder().decode(TranslationWSRawMessage.self, from: data) else {
            return nil
        }

        switch raw.type {
        case "status":
            guard let status = raw.status else { return nil }
            return .status(status)
        case "translation":
            guard let text = raw.text else { return nil }
            return .translation(text)
        case "transcription":
            guard let text = raw.text else { return nil }
            return .transcription(text)
        case "interrupted":
            return .interrupted
        case "error":
            return .error(raw.message ?? "Translation stream error")
        case "critical_confirmation":
            guard let confirmation = try? JSONDecoder().decode(CriticalConfirmation.self, from: data) else {
                return nil
            }
            return .criticalConfirmation(confirmation)
        case "verified_facts_summary":
            return .verifiedFactsSummary(raw.facts ?? [])
        default:
            return nil
        }
    }
}
