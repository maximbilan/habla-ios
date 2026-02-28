import Foundation

struct ConversationTurn: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    let role: ConversationRole
    let text: String
    let translatedText: String?
    let timestamp: Date

    init(
        id: UUID = UUID(),
        role: ConversationRole,
        text: String,
        translatedText: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.translatedText = translatedText
        self.timestamp = timestamp
    }
}

enum ConversationRole: String, Equatable, Sendable, Codable {
    case caller
    case interpreter
    case agent
    case callee

    var title: String {
        switch self {
        case .caller:
            return "Caller"
        case .interpreter:
            return "Interpreter"
        case .agent:
            return "Agent"
        case .callee:
            return "Callee"
        }
    }

    var alignsRight: Bool {
        switch self {
        case .caller, .callee:
            return true
        case .interpreter, .agent:
            return false
        }
    }
}

extension TranscriptEntry {
    func asConversationTurn() -> ConversationTurn {
        ConversationTurn(
            id: id,
            role: role == .agent ? .agent : .callee,
            text: textOriginal,
            translatedText: textEn,
            timestamp: timestamp
        )
    }
}
