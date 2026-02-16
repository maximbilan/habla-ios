//
//  AppReducer.swift
//  habla-ios
//

import Foundation

func appReducer(state: inout AppState, action: AppAction) {
    switch action {
    case .dialpadDigitPressed(let digit):
        state.phoneNumber.append(digit)

    case .dialpadBackspace:
        if !state.phoneNumber.isEmpty && state.phoneNumber != "+34" {
            state.phoneNumber.removeLast()
        }

    case .phoneNumberChanged(let number):
        state.phoneNumber = number

    case .initiateCall:
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

    case .serverURLChanged(let url):
        state.serverURL = url

    case .callHistoryLoaded(let calls):
        state.recentCalls = calls

    case .webSocketConnected:
        break

    case .webSocketDisconnected:
        break

    default:
        break
    }
}
