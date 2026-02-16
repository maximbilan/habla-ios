//
//  APIModels.swift
//  habla-ios
//

import Foundation

struct CallRequest: Codable, Sendable {
    let to: String
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
