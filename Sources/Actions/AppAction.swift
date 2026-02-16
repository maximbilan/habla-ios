//
//  AppAction.swift
//  habla-ios
//

import Foundation

enum AppAction: Sendable {
    // Dialer actions
    case dialpadDigitPressed(String)
    case dialpadBackspace
    case phoneNumberChanged(String)

    // Call lifecycle actions
    case initiateCall(to: String)
    case callInitiated(callSid: String)
    case callStatusUpdated(CallStatus)
    case callFailed(AppError)
    case endCall
    case callEnded

    // Audio actions
    case toggleMute
    case toggleSpeaker
    case inputAudioLevelUpdated(Float)
    case outputAudioLevelUpdated(Float)
    case receivingAudioChanged(Bool)

    // Audio pipeline actions
    case startAudioCapture
    case stopAudioCapture
    case audioCaptureFailed(AppError)

    // WebSocket actions
    case connectWebSocket(callSid: String)
    case webSocketConnected
    case webSocketDisconnected
    case webSocketError(AppError)

    // Timer actions
    case callTimerTick

    // Navigation
    case navigateTo(ActiveScreen)

    // Settings
    case serverURLChanged(String)

    // Call history
    case loadCallHistory
    case callHistoryLoaded([CallRecord])
    case saveCallRecord(CallRecord)

    // Error handling
    case clearError
}
