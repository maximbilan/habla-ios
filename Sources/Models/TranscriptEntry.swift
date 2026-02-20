import Foundation

struct TranscriptEntry: Equatable, Identifiable, Sendable {
    let id: UUID
    let role: TranscriptRole
    let textEs: String
    var textEn: String?
    let timestamp: Date

    init(
        id: UUID = UUID(),
        role: TranscriptRole,
        textEs: String,
        textEn: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.textEs = textEs
        self.textEn = textEn
        self.timestamp = timestamp
    }
}

enum TranscriptRole: String, Equatable, Sendable, Codable {
    case agent
    case callee
}
