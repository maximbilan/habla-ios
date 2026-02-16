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

    init(
        id: UUID = UUID(),
        phoneNumber: String,
        startedAt: Date = Date(),
        duration: TimeInterval = 0,
        status: String = "completed"
    ) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.startedAt = startedAt
        self.duration = duration
        self.status = status
    }

    func toCallRecord() -> CallRecord {
        CallRecord(
            id: id,
            phoneNumber: phoneNumber,
            startedAt: startedAt,
            duration: duration,
            status: status
        )
    }
}
