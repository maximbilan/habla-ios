//
//  APIModels.swift
//  habla-ios
//

struct CallRequest: Codable, Sendable {
    let to: String
    let from: String?
    let source_language: String
    let target_language: String
    let voice_gender: VoiceGender
}

struct CallResponse: Codable, Sendable {
    let call_sid: String
}

struct AgentCallRequest: Codable, Sendable {
    let to: String
    let from: String?
    let prompt: String
    let user_name: String
    let language: String
    let voice_gender: VoiceGender
}

struct AgentCallResponse: Codable, Sendable {
    let call_sid: String
}
