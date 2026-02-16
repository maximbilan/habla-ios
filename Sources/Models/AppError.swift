//
//  AppError.swift
//  habla-ios
//

import Foundation

enum AppError: Error, Equatable, Sendable, LocalizedError {
    case networkError(String)
    case webSocketError(String)
    case audioError(String)
    case callFailed(String)
    case microphonePermissionDenied

    var errorDescription: String? {
        switch self {
        case .networkError(let msg): return msg
        case .webSocketError(let msg): return msg
        case .audioError(let msg): return msg
        case .callFailed(let msg): return msg
        case .microphonePermissionDenied: return "Microphone access is required for calls"
        }
    }
}
