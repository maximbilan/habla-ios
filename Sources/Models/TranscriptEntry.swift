import Foundation

struct TranscriptEntry: Equatable, Identifiable, Sendable {
    let id: UUID
    let role: TranscriptRole
    let textOriginal: String
    var textEn: String?
    let timestamp: Date

    init(
        id: UUID = UUID(),
        role: TranscriptRole,
        textOriginal: String,
        textEn: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.textOriginal = textOriginal
        self.textEn = textEn
        self.timestamp = timestamp
    }
}

enum TranscriptRole: String, Equatable, Sendable, Codable {
    case agent
    case callee
}
