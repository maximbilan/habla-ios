//
//  NetworkMiddleware.swift
//  habla-ios
//

import Foundation

final class NetworkMiddleware: Middleware, @unchecked Sendable {
    private let networkService: NetworkService
    private let conversationBuffer: CallConversationBuffer

    init(
        networkService: NetworkService = NetworkService(),
        conversationBuffer: CallConversationBuffer = CallConversationBuffer()
    ) {
        self.networkService = networkService
        self.conversationBuffer = conversationBuffer
    }

    func process(action: AppAction, state: AppState, dispatch: @escaping @MainActor (AppAction) -> Void) {
        switch action {
        case .initiateCall(let phoneNumber):
            conversationBuffer.reset()
            let serverURL = state.serverURL
            let fromNumber = resolveCallerId(state: state)
            let sourceLanguage = state.translationSourceLanguage
            let targetLanguage = resolveTargetLanguage(for: phoneNumber, state: state)
            let voiceGender = state.selectedVoiceGender
            Task {
                do {
                    let response = try await networkService.initiateCall(
                        to: phoneNumber,
                        from: fromNumber,
                        sourceLanguage: sourceLanguage,
                        targetLanguage: targetLanguage,
                        voiceGender: voiceGender,
                        serverURL: serverURL
                    )
                    await MainActor.run {
                        dispatch(.callInitiated(callSid: response.call_sid))
                        dispatch(.connectWebSocket(callSid: response.call_sid))
                        dispatch(.startAudioCapture)
                    }
                } catch {
                    let appError = (error as? AppError) ?? .networkError(error.localizedDescription)
                    await MainActor.run {
                        dispatch(.callFailed(appError))
                    }
                }
            }

        case .endCall:
            guard let callSid = state.callSid else {
                Task { @MainActor in
                    dispatch(.callEnded)
                }
                return
            }
            let serverURL = state.serverURL
            let phoneNumber = state.phoneNumber
            let duration = state.callDuration
            let verifiedFacts = state.verifiedFactsSummary
            let conversation = conversationBuffer.snapshot()

            Task {
                do {
                    try await networkService.endCall(callSid: callSid, serverURL: serverURL)
                } catch {
                    // End the local call flow even if remote hangup fails.
                }

                let record = CallRecord(
                    phoneNumber: phoneNumber,
                    duration: duration,
                    status: "completed",
                    mode: .live,
                    verifiedFacts: verifiedFacts,
                    conversation: conversation
                )
                conversationBuffer.reset()
                await MainActor.run {
                    dispatch(.saveCallRecord(record))
                    dispatch(.openCallSummary(record))
                    dispatch(.callEnded)
                }
            }

        case .callFailed:
            conversationBuffer.reset()

        default:
            break
        }
    }

    private func resolveCallerId(state: AppState) -> String? {
        guard let selectedSid = state.callerId.selectedNumberSid else { return nil }
        return state.callerId.verifiedNumbers.first { $0.id == selectedSid }?.phoneNumber
    }

    private func resolveTargetLanguage(for phoneNumber: String, state: AppState) -> String {
        guard let memory = matchedCallerMemory(for: phoneNumber, state: state),
              let preferred = memory.preferredTargetLanguage,
              let language = TranslationLanguageCatalog.language(code: preferred) else {
            return state.translationTargetLanguage
        }
        return language.code
    }

    private func matchedCallerMemory(for phoneNumber: String, state: AppState) -> CallerMemory? {
        guard let phoneKey = CallerMemoryKey.normalize(phoneNumber: phoneNumber),
              let activePhoneKey = state.activeCallerMemoryPhoneKey,
              phoneKey == activePhoneKey,
              let memory = state.activeCallerMemory,
              memory.consentGranted else {
            return nil
        }
        return memory
    }
}
