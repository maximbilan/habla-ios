//
//  APIModels.swift
//  habla-ios
//

import Foundation

struct CallRequest: Codable, Sendable {
    let to: String
    let from: String?
}

struct CallResponse: Codable, Sendable {
    let call_sid: String
    let status: String
}

struct CallEndResponse: Codable, Sendable {
    let status: String
}

struct CallStatusResponse: Codable, Sendable {
    let call_sid: String
    let status: String
}

struct AgentCallRequest: Codable, Sendable {
    let to: String
    let from: String?
    let prompt: String
    let user_name: String
    let language: String
}

struct AgentCallResponse: Codable, Sendable {
    let call_sid: String
    let status: String
}

struct AgentCallStatusResponse: Codable, Sendable {
    let call_sid: String
    let status: String
    let transcript: [AgentTranscriptPayload]
}

struct AgentTranscriptPayload: Codable, Sendable {
    let role: String
    let text_es: String
    let text_en: String?
    let timestamp: String
}
