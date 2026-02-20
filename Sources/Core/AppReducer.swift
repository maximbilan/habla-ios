//
//  AppReducer.swift
//  habla-ios
//

import Foundation

func appReducer(state: inout AppState, action: AppAction) {
    switch action {
    case .setCallMode(let mode):
        state.callMode = mode

    case .dialpadDigitPressed(let digit):
        state.phoneNumber.append(digit)

    case .dialpadBackspace:
        if !state.phoneNumber.isEmpty && state.phoneNumber != "+34" {
            state.phoneNumber.removeLast()
        }

    case .phoneNumberChanged(let number):
        state.phoneNumber = number

    case .initiateCall:
        state.callMode = .translation
        state.callStatus = .initiating
        state.callError = nil
        state.callDuration = 0
        state.activeScreen = .activeCall

    case .callInitiated(let callSid):
        state.callSid = callSid
        state.callStatus = .connecting

    case .callStatusUpdated(let status):
        state.callStatus = status

    case .callFailed(let error):
        state.callStatus = .failed(error.localizedDescription)
        state.callError = error

    case .endCall:
        state.callStatus = .ended

    case .callEnded:
        state.callStatus = .idle
        state.callSid = nil
        state.activeScreen = .dialer
        state.agentStatus = .idle

    case .agentPromptChanged(let text):
        state.agentPrompt = text

    case .agentUserNameChanged(let name):
        state.agentUserName = name

    case .initiateAgentCall:
        state.callMode = .agent
        state.callStatus = .initiating
        state.callError = nil
        state.callDuration = 0
        state.agentTranscript = []
        state.agentStatus = .idle
        state.activeScreen = .agentCall

    case .agentCallInitiated(let callSid):
        state.callSid = callSid
        state.callStatus = .connecting

    case .agentCallFailed(let error):
        state.callStatus = .failed(error.localizedDescription)
        state.callError = error

    case .agentTranscriptReceived(let entry):
        state.agentTranscript.append(entry)

    case .agentTranscriptUpdated(let updatedEntry):
        if let index = state.agentTranscript.firstIndex(where: { $0.id == updatedEntry.id }) {
            state.agentTranscript[index] = updatedEntry
        } else {
            state.agentTranscript.append(updatedEntry)
        }

    case .agentStatusUpdated(let status):
        state.agentStatus = status

    case .agentMidCallInputChanged(let text):
        state.agentMidCallInput = text

    case .agentInstructionSent:
        state.agentMidCallInput = ""

    case .endAgentCall:
        state.callStatus = .ended

    case .agentCallEnded:
        state.callStatus = .idle
        state.callSid = nil
        state.agentStatus = .idle
        state.activeScreen = .dialer

    case .toggleMute:
        state.isMuted.toggle()

    case .toggleSpeaker:
        state.isSpeaker.toggle()

    case .inputAudioLevelUpdated(let level):
        state.inputAudioLevel = level

    case .outputAudioLevelUpdated(let level):
        state.outputAudioLevel = level

    case .receivingAudioChanged(let receiving):
        state.isReceivingAudio = receiving

    case .callTimerTick:
        state.callDuration += 1

    case .navigateTo(let screen):
        state.activeScreen = screen

    case .callHistoryLoaded(let calls):
        state.recentCalls = calls

    case .clearError:
        state.callError = nil

    case .agentWebSocketConnected:
        break

    case .agentWebSocketDisconnected:
        break

    case .agentWebSocketError(let error):
        state.callError = error

    case .webSocketConnected:
        break

    case .webSocketDisconnected:
        break

    default:
        break
    }
}
