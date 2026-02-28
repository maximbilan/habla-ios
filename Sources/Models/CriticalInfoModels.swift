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
