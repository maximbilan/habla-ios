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
}

struct CallResponse: Codable, Sendable {
    let call_sid: String
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
