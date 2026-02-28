//
//  CallRecordModel.swift
//  habla-ios
//

import Foundation
import SwiftData

@Model
final class CallRecordModel {
    var id: UUID
    var phoneNumber: String
    var startedAt: Date
    var duration: TimeInterval
    var status: String
    var verifiedFactsData: Data

    init(
        id: UUID = UUID(),
        phoneNumber: String,
        startedAt: Date = Date(),
        duration: TimeInterval = 0,
        status: String = "completed",
        verifiedFactsData: Data = Data()
    ) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.startedAt = startedAt
        self.duration = duration
        self.status = status
        self.verifiedFactsData = verifiedFactsData
    }

    func toCallRecord(
        conversation: [ConversationTurn] = []
    ) -> CallRecord {
        CallRecord(
            id: id,
            phoneNumber: phoneNumber,
            startedAt: startedAt,
            duration: duration,
            status: status,
            verifiedFacts: decodeVerifiedFacts(verifiedFactsData),
            conversation: conversation
        )
    }

    static func encodeVerifiedFacts(_ facts: [VerifiedFact]) -> Data {
        (try? JSONEncoder().encode(facts)) ?? Data()
    }

    private func decodeVerifiedFacts(_ data: Data) -> [VerifiedFact] {
        guard !data.isEmpty else { return [] }
        return (try? JSONDecoder().decode([VerifiedFact].self, from: data)) ?? []
    }
}
