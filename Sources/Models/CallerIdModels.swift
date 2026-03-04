struct VerifiedCallerId: Equatable, Identifiable, Sendable {
    let id: String
    let phoneNumber: String
    let friendlyName: String?
}

struct CallerIdVerifyResponse: Codable, Sendable {
    let status: String
    let validationCode: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case status
        case validationCode = "validation_code"
        case message
    }
}

struct CallerIdStatusResponse: Codable, Sendable {
    let verified: Bool
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

    enum CodingKeys: String, CodingKey {
        case phoneNumber = "phone_number"
        case friendlyName = "friendly_name"
        case sid
    }
}
