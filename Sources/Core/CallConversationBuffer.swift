//
//  CallConversationBuffer.swift
//  habla-ios
//

import Foundation

final class CallConversationBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var turns: [ConversationTurn] = []

    func reset() {
        lock.lock()
        turns.removeAll(keepingCapacity: false)
        lock.unlock()
    }

    func append(role: ConversationRole, text: String, timestamp: Date = Date()) {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }

        lock.lock()
        turns.append(
            ConversationTurn(
                role: role,
                text: normalized,
                timestamp: timestamp
            )
        )
        lock.unlock()
    }

    func snapshot() -> [ConversationTurn] {
        lock.lock()
        let copy = turns
        lock.unlock()
        return copy.sorted { $0.timestamp < $1.timestamp }
    }
}
