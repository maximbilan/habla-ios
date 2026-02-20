import Foundation

final class AgentNetworkMiddleware: Middleware, @unchecked Sendable {
    private let networkService: AgentNetworkService

    init(networkService: AgentNetworkService = AgentNetworkService()) {
        self.networkService = networkService
    }

    func process(action: AppAction, state: AppState, dispatch: @escaping @MainActor (AppAction) -> Void) {
        switch action {
        case .initiateAgentCall(let phoneNumber, let prompt, let userName):
            let serverURL = state.serverURL
            let fromNumber = resolveCallerId(state: state)

            Task {
                do {
                    let response = try await networkService.initiateAgentCall(
                        to: phoneNumber,
                        from: fromNumber,
                        prompt: prompt,
                        userName: userName,
                        language: "es",
                        serverURL: serverURL
                    )

                    await MainActor.run {
                        dispatch(.agentCallInitiated(callSid: response.call_sid))
                        dispatch(.connectAgentWebSocket(callSid: response.call_sid))
                    }
                } catch {
                    let appError = (error as? AppError) ?? .networkError(error.localizedDescription)
                    await MainActor.run {
                        dispatch(.agentCallFailed(appError))
                    }
                }
            }

        case .endAgentCall:
            guard let callSid = state.callSid else {
                Task { @MainActor in
                    dispatch(.agentCallEnded)
                    dispatch(.callEnded)
                }
                return
            }

            let serverURL = state.serverURL
            let phoneNumber = state.phoneNumber
            let duration = state.callDuration

            Task {
                do {
                    try await networkService.endAgentCall(callSid: callSid, serverURL: serverURL)
                } catch {
                    print("[AgentNetworkMiddleware] End call error: \(error)")
                }

                let record = CallRecord(
                    phoneNumber: phoneNumber,
                    duration: duration,
                    status: "completed"
                )
                await MainActor.run {
                    dispatch(.saveCallRecord(record))
                    dispatch(.agentCallEnded)
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
