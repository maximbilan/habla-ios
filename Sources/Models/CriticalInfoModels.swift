import Foundation

struct VerifiedFact: Codable, Equatable, Sendable, Identifiable {
    let type: String
    let value: String
    let confidence: Double
    let verified: Bool
    let occurrences: Int
    let lastRole: String?

    var id: String { "\(type)|\(value.lowercased())" }

    enum CodingKeys: String, CodingKey {
        case type
        case value
        case confidence
        case verified
        case occurrences
        case lastRole = "last_role"
    }

    init(
        type: String,
        value: String,
        confidence: Double = 0,
        verified: Bool = false,
        occurrences: Int = 1,
        lastRole: String? = nil
    ) {
        self.type = type
        self.value = value
        self.confidence = confidence
        self.verified = verified
        self.occurrences = occurrences
        self.lastRole = lastRole
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        value = try container.decode(String.self, forKey: .value)
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 0
        verified = try container.decodeIfPresent(Bool.self, forKey: .verified) ?? false
        occurrences = try container.decodeIfPresent(Int.self, forKey: .occurrences) ?? 1
        lastRole = try container.decodeIfPresent(String.self, forKey: .lastRole)
    }

    var displayType: String {
        switch type {
        case "phone_number":
            return "Phone"
        case "money_amount":
            return "Amount"
        case "address":
            return "Address"
        case "date":
            return "Date"
        case "name":
            return "Name"
        default:
            return type.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

struct CriticalConfirmation: Codable, Equatable, Sendable, Identifiable {
    let factType: String
    let reason: String
    let sourceValue: String?
    let candidateValue: String
    let confidence: Double
    let promptEn: String
    let promptEs: String

    var id: String {
        "\(factType)|\(reason)|\(sourceValue ?? "")|\(candidateValue)"
    }

    enum CodingKeys: String, CodingKey {
        case factType = "fact_type"
        case reason
        case sourceValue = "source_value"
        case candidateValue = "candidate_value"
        case confidence
        case promptEn = "prompt_en"
        case promptEs = "prompt_es"
    }

    init(
        factType: String,
        reason: String,
        sourceValue: String?,
        candidateValue: String,
        confidence: Double,
        promptEn: String,
        promptEs: String
    ) {
        self.factType = factType
        self.reason = reason
        self.sourceValue = sourceValue
        self.candidateValue = candidateValue
        self.confidence = confidence
        self.promptEn = promptEn
        self.promptEs = promptEs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        factType = try container.decode(String.self, forKey: .factType)
        reason = try container.decodeIfPresent(String.self, forKey: .reason) ?? "low_confidence"
        sourceValue = try container.decodeIfPresent(String.self, forKey: .sourceValue)
        candidateValue = try container.decodeIfPresent(String.self, forKey: .candidateValue) ?? ""
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 0
        promptEn = try container.decodeIfPresent(String.self, forKey: .promptEn)
            ?? "Please confirm the critical detail."
        promptEs = try container.decodeIfPresent(String.self, forKey: .promptEs)
            ?? "Por favor confirma el dato importante."
    }
}

struct GoalField: Codable, Equatable, Sendable, Identifiable {
    let name: String
    let value: String
    let confidence: Double
    let occurrences: Int
    let sourceRole: String?
    let verified: Bool

    var id: String { "\(name)|\(value.lowercased())" }

    enum CodingKeys: String, CodingKey {
        case name
        case value
        case confidence
        case occurrences
        case sourceRole = "source_role"
        case verified
    }

    init(
        name: String,
        value: String,
        confidence: Double = 0,
        occurrences: Int = 1,
        sourceRole: String? = nil,
        verified: Bool = false
    ) {
        self.name = name
        self.value = value
        self.confidence = confidence
        self.occurrences = occurrences
        self.sourceRole = sourceRole
        self.verified = verified
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        value = try container.decode(String.self, forKey: .value)
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 0
        occurrences = try container.decodeIfPresent(Int.self, forKey: .occurrences) ?? 1
        sourceRole = try container.decodeIfPresent(String.self, forKey: .sourceRole)
        verified = try container.decodeIfPresent(Bool.self, forKey: .verified) ?? false
    }

    var displayName: String {
        switch name {
        case "next_step":
            return "Next Step"
        case "phone_number":
            return "Phone"
        default:
            return name.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

struct GoalProgressPayload: Codable, Equatable, Sendable {
    let objective: String
    let requiredFields: [String]
    let fields: [GoalField]
    let missingFields: [String]
    let completionRate: Double
    let success: Bool

    enum CodingKeys: String, CodingKey {
        case objective
        case requiredFields = "required_fields"
        case fields
        case missingFields = "missing_fields"
        case completionRate = "completion_rate"
        case success
    }

    init(
        objective: String,
        requiredFields: [String],
        fields: [GoalField],
        missingFields: [String],
        completionRate: Double,
        success: Bool
    ) {
        self.objective = objective
        self.requiredFields = requiredFields
        self.fields = fields
        self.missingFields = missingFields
        self.completionRate = completionRate
        self.success = success
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        objective = try container.decodeIfPresent(String.self, forKey: .objective) ?? ""
        requiredFields = try container.decodeIfPresent([String].self, forKey: .requiredFields) ?? []
        fields = try container.decodeIfPresent([GoalField].self, forKey: .fields) ?? []
        missingFields = try container.decodeIfPresent([String].self, forKey: .missingFields) ?? []
        completionRate = try container.decodeIfPresent(Double.self, forKey: .completionRate) ?? 0
        success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? false
    }
}

struct GoalResultFieldValue: Codable, Equatable, Sendable {
    let value: String
    let confidence: Double
    let occurrences: Int
    let sourceRole: String?
    let verified: Bool

    enum CodingKeys: String, CodingKey {
        case value
        case confidence
        case occurrences
        case sourceRole = "source_role"
        case verified
    }
}

struct GoalStructuredResult: Codable, Equatable, Sendable {
    let objective: String
    let requiredFields: [String]
    let fields: [String: GoalResultFieldValue]
    let missingFields: [String]
    let success: Bool

    enum CodingKeys: String, CodingKey {
        case objective
        case requiredFields = "required_fields"
        case fields
        case missingFields = "missing_fields"
        case success
    }
}

struct GoalResultSummary: Codable, Equatable, Sendable {
    let objective: String
    let requiredFields: [String]
    let fields: [GoalField]
    let missingFields: [String]
    let completionRate: Double
    let success: Bool
    let summaryEn: String
    let summaryEs: String
    let result: GoalStructuredResult?

    enum CodingKeys: String, CodingKey {
        case objective
        case requiredFields = "required_fields"
        case fields
        case missingFields = "missing_fields"
        case completionRate = "completion_rate"
        case success
        case summaryEn = "summary_en"
        case summaryEs = "summary_es"
        case result
    }

    init(
        objective: String,
        requiredFields: [String],
        fields: [GoalField],
        missingFields: [String],
        completionRate: Double,
        success: Bool,
        summaryEn: String,
        summaryEs: String,
        result: GoalStructuredResult?
    ) {
        self.objective = objective
        self.requiredFields = requiredFields
        self.fields = fields
        self.missingFields = missingFields
        self.completionRate = completionRate
        self.success = success
        self.summaryEn = summaryEn
        self.summaryEs = summaryEs
        self.result = result
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        objective = try container.decodeIfPresent(String.self, forKey: .objective) ?? ""
        requiredFields = try container.decodeIfPresent([String].self, forKey: .requiredFields) ?? []
        fields = try container.decodeIfPresent([GoalField].self, forKey: .fields) ?? []
        missingFields = try container.decodeIfPresent([String].self, forKey: .missingFields) ?? []
        completionRate = try container.decodeIfPresent(Double.self, forKey: .completionRate) ?? 0
        success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? false
        summaryEn = try container.decodeIfPresent(String.self, forKey: .summaryEn) ?? ""
        summaryEs = try container.decodeIfPresent(String.self, forKey: .summaryEs) ?? ""
        result = try container.decodeIfPresent(GoalStructuredResult.self, forKey: .result)
    }
}
