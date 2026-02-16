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
            Task {
                do {
                    let response = try await networkService.initiateCall(to: phoneNumber, serverURL: serverURL)
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
            guard let callSid = state.callSid else { return }
            let serverURL = state.serverURL
            let phoneNumber = state.phoneNumber
            let duration = state.callDuration

            Task {
                do {
                    try await networkService.endCall(callSid: callSid, serverURL: serverURL)
                } catch {
                    print("[NetworkMiddleware] End call error: \(error)")
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
}
