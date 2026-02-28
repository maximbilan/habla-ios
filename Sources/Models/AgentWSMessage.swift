import Foundation

enum AgentWSMessage: Sendable {
    case status(String)
    case agentStatus(String)
    case transcript(role: String, textEs: String, textEn: String?, timestamp: String)
    case transcriptUpdate(role: String, textEs: String, textEn: String, timestamp: String)
    case criticalConfirmation(CriticalConfirmation)
    case verifiedFactsSummary([VerifiedFact])
    case goalProgress(GoalProgressPayload)
    case goalResultSummary(GoalResultSummary)
}

private struct AgentWSRawMessage: Decodable, Sendable {
    let type: String
    let status: String?
    let role: String?
    let text_es: String?
    let text_en: String?
    let timestamp: String?
    let facts: [VerifiedFact]?
}

extension AgentWSMessage {
    static func decode(from text: String) -> AgentWSMessage? {
        guard let data = text.data(using: .utf8),
              let raw = try? JSONDecoder().decode(AgentWSRawMessage.self, from: data) else {
            return nil
        }

        switch raw.type {
        case "status":
            guard let status = raw.status else { return nil }
            return .status(status)
        case "agent_status":
            guard let status = raw.status else { return nil }
            return .agentStatus(status)
        case "transcript":
            guard let role = raw.role,
                  let textEs = raw.text_es,
                  let timestamp = raw.timestamp else { return nil }
            return .transcript(role: role, textEs: textEs, textEn: raw.text_en, timestamp: timestamp)
        case "transcript_update":
            guard let role = raw.role,
                  let textEs = raw.text_es,
                  let textEn = raw.text_en,
                  let timestamp = raw.timestamp else { return nil }
            return .transcriptUpdate(role: role, textEs: textEs, textEn: textEn, timestamp: timestamp)
        case "critical_confirmation":
            guard let confirmation = try? JSONDecoder().decode(CriticalConfirmation.self, from: data) else {
                return nil
            }
            return .criticalConfirmation(confirmation)
        case "verified_facts_summary":
            return .verifiedFactsSummary(raw.facts ?? [])
        case "goal_progress":
            guard let progress = try? JSONDecoder().decode(GoalProgressPayload.self, from: data) else {
                return nil
            }
            return .goalProgress(progress)
        case "goal_result_summary":
            guard let summary = try? JSONDecoder().decode(GoalResultSummary.self, from: data) else {
                return nil
            }
            return .goalResultSummary(summary)
        default:
            return nil
        }
    }
}
