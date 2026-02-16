//
//  CallTimerMiddleware.swift
//  habla-ios
//

import Foundation

final class CallTimerMiddleware: Middleware, @unchecked Sendable {
    private var timerTask: Task<Void, Never>?

    func process(action: AppAction, state: AppState, dispatch: @escaping @MainActor (AppAction) -> Void) {
        switch action {
        case .callStatusUpdated(.connected):
            timerTask?.cancel()
            timerTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    if !Task.isCancelled {
                        await MainActor.run {
                            dispatch(.callTimerTick)
                        }
                    }
                }
            }

        case .endCall, .callFailed, .callEnded:
            timerTask?.cancel()
            timerTask = nil

        default:
            break
        }
    }
}
