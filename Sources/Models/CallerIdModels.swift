import Foundation

struct VerifiedCallerId: Equatable, Identifiable, Sendable {
    let id: String
    let phoneNumber: String
    let friendlyName: String?
    let dateCreated: String?
}

struct CallerIdVerifyResponse: Codable, Sendable {
    let status: String
    let phoneNumber: String
    let validationCode: String?
    let callSid: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case status
        case phoneNumber = "phone_number"
        case validationCode = "validation_code"
        case callSid = "call_sid"
        case message
    }
}

struct CallerIdStatusResponse: Codable, Sendable {
    let phoneNumber: String
    let verified: Bool
    let friendlyName: String?
    let sid: String?

    enum CodingKeys: String, CodingKey {
        case phoneNumber = "phone_number"
        case verified
        case friendlyName = "friendly_name"
        case sid
    }
}

struct CallerIdListResponse: Codable, Sendable {
    let callerIds: [CallerIdEntry]

    enum CodingKeys: String, CodingKey {
        case callerIds = "caller_ids"
    }
}

struct CallerIdEntry: Codable, Sendable {
    let phoneNumber: String
    let friendlyName: String?
    let sid: String
    let dateCreated: String?

    enum CodingKeys: String, CodingKey {
        case phoneNumber = "phone_number"
        case friendlyName = "friendly_name"
        case sid
        case dateCreated = "date_created"
    }
}
