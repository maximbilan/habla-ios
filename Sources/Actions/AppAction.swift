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
    case setCallMode(CallMode)
    case initiateCall(to: String)
    case callInitiated(callSid: String)
    case callStatusUpdated(CallStatus)
    case callFailed(AppError)
    case endCall
    case callEnded

    // Agent mode actions
    case agentPromptChanged(String)
    case agentUserNameChanged(String)
    case initiateAgentCall(to: String, prompt: String, userName: String)
    case agentCallInitiated(callSid: String)
    case agentCallFailed(AppError)

    // Agent transcript
    case agentTranscriptReceived(TranscriptEntry)
    case agentTranscriptUpdated(TranscriptEntry)
    case agentStatusUpdated(AgentStatus)

    // Agent mid-call instructions
    case agentMidCallInputChanged(String)
    case sendAgentInstruction(String)
    case agentInstructionSent

    // Agent end conversation
    case endAgentConversation(String)
    case endAgentCall
    case agentCallEnded

    // Agent WebSocket
    case connectAgentWebSocket(callSid: String)
    case agentWebSocketConnected
    case agentWebSocketDisconnected
    case agentWebSocketError(AppError)

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

    // Call history
    case loadCallHistory
    case callHistoryLoaded([CallRecord])
    case saveCallRecord(CallRecord)

    // Caller ID actions
    case callerIdPhoneNumberChanged(String)
    case callerIdFriendlyNameChanged(String)
    case startCallerIdVerification
    case callerIdVerificationStarted(validationCode: String)
    case callerIdVerificationCompleted
    case callerIdVerificationFailed(AppError)
    case checkCallerIdStatus
    case callerIdStatusChecked(verified: Bool)
    case loadVerifiedCallerIds
    case verifiedCallerIdsLoaded([VerifiedCallerId])
    case selectCallerId(String?)
    case deleteCallerId(String)
    case callerIdDeleted(String)
    case clearCallerIdError

    // Error handling
    case clearError
}
