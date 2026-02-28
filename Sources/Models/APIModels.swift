//
//  APIModels.swift
//  habla-ios
//

import Foundation

struct CallRequest: Codable, Sendable {
    let to: String
    let from: String?
    let source_language: String
    let target_language: String
    let voice_gender: VoiceGender
}

struct CallResponse: Codable, Sendable {
    let call_sid: String
    let status: String
}

struct AgentCallRequest: Codable, Sendable {
    let to: String
    let from: String?
    let prompt: String
    let user_name: String
    let language: String
    let voice_gender: VoiceGender
    let goal_schema: AgentGoalSchema?
}

struct AgentGoalSchema: Codable, Sendable {
    let objective: String
    let required_fields: [String]
}

struct AgentCallResponse: Codable, Sendable {
    let call_sid: String
    let status: String
}
