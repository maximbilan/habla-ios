//
//  CallRecord.swift
//  habla-ios
//

import Foundation

struct CallRecord: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    let phoneNumber: String
    let startedAt: Date
    let duration: TimeInterval
    let status: String
    let verifiedFacts: [VerifiedFact]

    init(
        id: UUID = UUID(),
        phoneNumber: String,
        startedAt: Date = Date(),
        duration: TimeInterval = 0,
        status: String = "completed",
        verifiedFacts: [VerifiedFact] = []
    ) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.startedAt = startedAt
        self.duration = duration
        self.status = status
        self.verifiedFacts = verifiedFacts
    }
}
