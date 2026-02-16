//
//  AppState.swift
//  habla-ios
//

import Foundation

struct AppState: Equatable {
    // Call state
    var callStatus: CallStatus = .idle
    var callSid: String? = nil
    var phoneNumber: String = "+34"
    var callDuration: TimeInterval = 0
    var callError: AppError? = nil

    // Audio state
    var isMuted: Bool = false
    var isSpeaker: Bool = false
    var inputAudioLevel: Float = 0.0
    var outputAudioLevel: Float = 0.0
    var isReceivingAudio: Bool = false

    // UI state
    var dialpadInput: String = ""
    var activeScreen: ActiveScreen = .dialer

    // Settings
    var serverURL: String = "http://localhost:8000"

    // Call history
    var recentCalls: [CallRecord] = []
}

enum CallStatus: Equatable, Sendable {
    case idle
    case initiating
    case connecting
    case ringing
    case connected
    case ended
    case failed(String)
}

enum ActiveScreen: Equatable, Sendable {
    case dialer
    case activeCall
    case settings
}
