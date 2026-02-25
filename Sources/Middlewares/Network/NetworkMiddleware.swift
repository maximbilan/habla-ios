//
//  NetworkMiddleware.swift
//  habla-ios
//

import Foundation

final class NetworkMiddleware: Middleware, @unchecked Sendable {
    private let networkService: NetworkService

    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }

    func process(action: AppAction, state: AppState, dispatch: @escaping @MainActor (AppAction) -> Void) {
        switch action {
        case .initiateCall(let phoneNumber):
            let serverURL = state.serverURL
            let fromNumber = resolveCallerId(state: state)
            let sourceLanguage = state.translationSourceLanguage
            let targetLanguage = state.translationTargetLanguage
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

            Task {
                do {
                    try await networkService.endCall(callSid: callSid, serverURL: serverURL)
                } catch {
                    // End the local call flow even if remote hangup fails.
                }

                let record = CallRecord(
                    phoneNumber: phoneNumber,
                    duration: duration,
                    status: "completed"
                )
                await MainActor.run {
                    dispatch(.saveCallRecord(record))
                    dispatch(.callEnded)
                }
            }

        default:
            break
        }
    }

    private func resolveCallerId(state: AppState) -> String? {
        guard let selectedSid = state.callerId.selectedNumberSid else { return nil }
        return state.callerId.verifiedNumbers.first { $0.id == selectedSid }?.phoneNumber
    }
}
