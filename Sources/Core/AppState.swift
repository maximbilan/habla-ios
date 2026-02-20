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
    var callMode: CallMode = .translation

    // Agent mode
    var agentPrompt: String = ""
    var agentUserName: String = UserDefaults.standard.string(forKey: "agentUserName") ?? ""
    var agentTranscript: [TranscriptEntry] = []
    var agentStatus: AgentStatus = .idle
    var agentMidCallInput: String = ""

    // Settings
    var serverURL: String = AppConfig.backendURL

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

enum ActiveScreen: Equatable, Hashable, Sendable {
    case dialer
    case callHistory
    case activeCall
    case agentSetup
    case agentCall
    case settings
}

enum CallMode: Equatable, Sendable {
    case translation
    case agent
}

enum AgentStatus: Equatable, Sendable {
    case idle
    case listening
    case speaking
    case thinking
}
