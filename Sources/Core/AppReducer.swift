//
//  AppReducer.swift
//  habla-ios
//

import Foundation

func appReducer(state: inout AppState, action: AppAction) {
    switch action {
    case .setCallMode(let mode):
        state.callMode = mode

    case .dialCountryChanged(let countryCode):
        let oldCountryCode = state.selectedDialCountryCode
        state.selectedDialCountryCode = countryCode
        state.phoneNumber = applyDialingCountryChange(
            phoneNumber: state.phoneNumber,
            from: oldCountryCode,
            to: countryCode
        )
        UserDefaults.standard.set(countryCode, forKey: AppState.dialCountryCodeKey)

    case .dialpadDigitPressed(let digit):
        state.phoneNumber.append(digit)

    case .dialpadBackspace:
        let dialCode = PhoneCountryCatalog.dialCode(for: state.selectedDialCountryCode)
        if state.phoneNumber.count > dialCode.count {
            state.phoneNumber.removeLast()
        } else {
            state.phoneNumber = dialCode
        }

    case .phoneNumberChanged(let number):
        state.phoneNumber = number
        if let resolvedCountryCode = resolveCountryCode(for: number) {
            state.selectedDialCountryCode = resolvedCountryCode
            UserDefaults.standard.set(resolvedCountryCode, forKey: AppState.dialCountryCodeKey)
        }

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
        state.agentTranscript = []
        state.agentMidCallInput = ""

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
        if let index = state.agentTranscript.firstIndex(where: { $0.id == entry.id }) {
            state.agentTranscript[index] = mergedTranscriptEntry(existing: state.agentTranscript[index], incoming: entry)
        } else if let index = state.agentTranscript.lastIndex(where: { likelySameTranscriptEntry($0, entry) }) {
            state.agentTranscript[index] = mergedTranscriptEntry(existing: state.agentTranscript[index], incoming: entry)
        } else {
            state.agentTranscript.append(entry)
        }

    case .agentTranscriptUpdated(let updatedEntry):
        if let index = state.agentTranscript.firstIndex(where: { $0.id == updatedEntry.id }) {
            state.agentTranscript[index] = mergedTranscriptEntry(existing: state.agentTranscript[index], incoming: updatedEntry)
        } else if let index = state.agentTranscript.lastIndex(where: { likelySameTranscriptEntry($0, updatedEntry) }) {
            state.agentTranscript[index] = mergedTranscriptEntry(existing: state.agentTranscript[index], incoming: updatedEntry)
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
        state.agentTranscript = []
        state.agentMidCallInput = ""

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

    case .callerIdPhoneNumberChanged(let number):
        state.callerId.phoneNumber = number
        if let resolvedCountryCode = resolveCountryCode(for: number) {
            state.callerId.selectedCountryCode = resolvedCountryCode
            UserDefaults.standard.set(resolvedCountryCode, forKey: CallerIdState.selectedCountryCodeKey)
        }

    case .callerIdCountryChanged(let countryCode):
        let oldCountryCode = state.callerId.selectedCountryCode
        state.callerId.selectedCountryCode = countryCode
        state.callerId.phoneNumber = applyDialingCountryChange(
            phoneNumber: state.callerId.phoneNumber,
            from: oldCountryCode,
            to: countryCode
        )
        UserDefaults.standard.set(countryCode, forKey: CallerIdState.selectedCountryCodeKey)

    case .callerIdFriendlyNameChanged(let name):
        state.callerId.friendlyName = name

    case .startCallerIdVerification:
        state.callerId.isLoading = true
        state.callerId.error = nil
        state.callerId.verificationStatus = .verifying
        state.callerId.validationCode = nil

    case .callerIdVerificationStarted(let code):
        state.callerId.isLoading = false
        state.callerId.validationCode = code
        state.callerId.verificationStatus = .verifying

    case .callerIdVerificationCompleted:
        state.callerId.isLoading = false
        state.callerId.verificationStatus = .verified
        state.callerId.validationCode = nil

    case .callerIdVerificationFailed(let error):
        state.callerId.isLoading = false
        state.callerId.verificationStatus = .failed(error.localizedDescription)
        state.callerId.error = error
        state.callerId.validationCode = nil

    case .checkCallerIdStatus:
        state.callerId.isLoading = true

    case .callerIdStatusChecked(let verified):
        state.callerId.isLoading = false
        state.callerId.verificationStatus = verified ? .verified : .unverified

    case .loadVerifiedCallerIds:
        state.callerId.isLoading = true
        state.callerId.error = nil

    case .verifiedCallerIdsLoaded(let ids):
        state.callerId.isLoading = false
        state.callerId.verifiedNumbers = ids
        if let selectedSid = state.callerId.selectedNumberSid,
           !ids.contains(where: { $0.id == selectedSid }) {
            state.callerId.selectedNumberSid = nil
        }
        if state.callerId.selectedNumberSid == nil, let first = ids.first {
            state.callerId.selectedNumberSid = first.id
        }

    case .selectCallerId(let sid):
        state.callerId.selectedNumberSid = sid

    case .deleteCallerId:
        state.callerId.isLoading = true
        state.callerId.error = nil

    case .callerIdDeleted(let sid):
        state.callerId.isLoading = false
        state.callerId.verifiedNumbers.removeAll { $0.id == sid }
        if state.callerId.selectedNumberSid == sid {
            state.callerId.selectedNumberSid = state.callerId.verifiedNumbers.first?.id
        }

    case .clearCallerIdError:
        state.callerId.error = nil

    case .translationSourceLanguageChanged(let code):
        guard let language = TranslationLanguageCatalog.language(code: code) else {
            break
        }

        state.translationSourceLanguage = language.code
        UserDefaults.standard.set(language.code, forKey: AppState.translationSourceLanguageKey)

        if state.translationTargetLanguage == language.code {
            let preferred = TranslationLanguageCatalog.defaultTarget.code
            let replacement = preferred == language.code
                ? TranslationLanguageCatalog.fallbackLanguage(excluding: language.code).code
                : preferred
            state.translationTargetLanguage = replacement
            UserDefaults.standard.set(replacement, forKey: AppState.translationTargetLanguageKey)
        }

    case .translationTargetLanguageChanged(let code):
        guard let language = TranslationLanguageCatalog.language(code: code) else {
            break
        }

        state.translationTargetLanguage = language.code
        UserDefaults.standard.set(language.code, forKey: AppState.translationTargetLanguageKey)

        if state.translationSourceLanguage == language.code {
            let preferred = TranslationLanguageCatalog.defaultSource.code
            let replacement = preferred == language.code
                ? TranslationLanguageCatalog.fallbackLanguage(excluding: language.code).code
                : preferred
            state.translationSourceLanguage = replacement
            UserDefaults.standard.set(replacement, forKey: AppState.translationSourceLanguageKey)
        }

    case .backendServiceChanged(let service):
        state.selectedBackendService = service
        UserDefaults.standard.set(service.rawValue, forKey: AppState.selectedBackendServiceKey)

    case .voiceGenderChanged(let voiceGender):
        state.selectedVoiceGender = voiceGender
        UserDefaults.standard.set(voiceGender.rawValue, forKey: AppState.selectedVoiceGenderKey)

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

private func normalizedTranscriptText(_ text: String) -> String {
    text
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "  ", with: " ")
        .lowercased()
}

private func likelySameTranscriptEntry(_ lhs: TranscriptEntry, _ rhs: TranscriptEntry) -> Bool {
    guard lhs.role == rhs.role else { return false }
    guard normalizedTranscriptText(lhs.textEs) == normalizedTranscriptText(rhs.textEs) else { return false }
    return abs(lhs.timestamp.timeIntervalSince(rhs.timestamp)) <= 2.0
}

private func mergedTranscriptEntry(existing: TranscriptEntry, incoming: TranscriptEntry) -> TranscriptEntry {
    TranscriptEntry(
        id: existing.id,
        role: incoming.role,
        textEs: incoming.textEs,
        textEn: incoming.textEn ?? existing.textEn,
        timestamp: existing.timestamp
    )
}

private func resolveCountryCode(for rawPhoneNumber: String) -> String? {
    let normalized = rawPhoneNumber
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: " ", with: "")

    if let matchedCountry = PhoneCountryCatalog.countryForPhoneNumber(normalized) {
        return matchedCountry.isoCode
    }

    if normalized.hasPrefix("+") {
        return PhoneCountryCatalog.manualCountry.isoCode
    }

    return nil
}

private func applyDialingCountryChange(phoneNumber: String, from oldCountryCode: String, to newCountryCode: String) -> String {
    let oldDialCode = PhoneCountryCatalog.dialCode(for: oldCountryCode)
    let newDialCode = PhoneCountryCatalog.dialCode(for: newCountryCode)
    let manualCountryCode = PhoneCountryCatalog.manualCountry.isoCode

    var subscriber = phoneNumber
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: " ", with: "")

    if oldCountryCode == newCountryCode {
        return subscriber.isEmpty ? newDialCode : subscriber
    }

    if oldCountryCode == manualCountryCode {
        if let matchedCountry = PhoneCountryCatalog.countryForPhoneNumber(subscriber),
           subscriber.hasPrefix(matchedCountry.dialCode) {
            subscriber.removeFirst(matchedCountry.dialCode.count)
            return newDialCode + subscriber
        }

        if subscriber.hasPrefix("+") {
            subscriber.removeFirst()
        }

        return newDialCode + subscriber
    }

    if subscriber.hasPrefix(oldDialCode) {
        subscriber.removeFirst(oldDialCode.count)
        return newDialCode + subscriber
    }

    if let matchedCountry = PhoneCountryCatalog.countryForPhoneNumber(subscriber),
       subscriber.hasPrefix(matchedCountry.dialCode) {
        subscriber.removeFirst(matchedCountry.dialCode.count)
        return newDialCode + subscriber
    }

    if subscriber.hasPrefix("+") {
        subscriber.removeFirst()
    }

    return newDialCode + subscriber
}
