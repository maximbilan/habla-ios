import Foundation

final class CallerIdMiddleware: Middleware, @unchecked Sendable {
    private let callerIdService: CallerIdService

    init(callerIdService: CallerIdService = CallerIdService()) {
        self.callerIdService = callerIdService
    }

    func process(action: AppAction, state: AppState, dispatch: @escaping @MainActor (AppAction) -> Void) {
        switch action {
        case .startCallerIdVerification:
            let phoneNumber = state.callerId.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            let friendlyName = state.callerId.friendlyName.trimmingCharacters(in: .whitespacesAndNewlines)
            let serverURL = state.serverURL

            guard !phoneNumber.isEmpty else {
                Task { @MainActor in
                    dispatch(.callerIdVerificationFailed(.networkError("Phone number is required")))
                }
                return
            }

            Task {
                do {
                    let response = try await callerIdService.startVerification(
                        phoneNumber: phoneNumber,
                        friendlyName: friendlyName,
                        serverURL: serverURL
                    )

                    if let code = response.validationCode, !code.isEmpty {
                        await MainActor.run {
                            dispatch(.callerIdVerificationStarted(validationCode: code))
                        }
                    } else {
                        let message = response.message ?? "Verification code is missing"
                        await MainActor.run {
                            dispatch(.callerIdVerificationFailed(.networkError(message)))
                        }
                    }
                } catch {
                    let appError = (error as? AppError) ?? .networkError(error.localizedDescription)
                    await MainActor.run {
                        dispatch(.callerIdVerificationFailed(appError))
                    }
                }
            }

        case .checkCallerIdStatus:
            let phoneNumber = state.callerId.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            let serverURL = state.serverURL
            guard !phoneNumber.isEmpty else {
                Task { @MainActor in
                    dispatch(.callerIdStatusChecked(verified: false))
                }
                return
            }

            Task {
                do {
                    for _ in 0..<5 {
                        try await Task.sleep(for: .seconds(2))
                        let response = try await callerIdService.checkStatus(
                            phoneNumber: phoneNumber,
                            serverURL: serverURL
                        )
                        if response.verified {
                            await MainActor.run {
                                dispatch(.callerIdStatusChecked(verified: true))
                                dispatch(.callerIdVerificationCompleted)
                                dispatch(.loadVerifiedCallerIds)
                            }
                            return
                        }
                    }

                    await MainActor.run {
                        dispatch(.callerIdStatusChecked(verified: false))
                    }
                } catch {
                    let appError = (error as? AppError) ?? .networkError(error.localizedDescription)
                    await MainActor.run {
                        dispatch(.callerIdVerificationFailed(appError))
                    }
                }
            }

        case .loadVerifiedCallerIds:
            let serverURL = state.serverURL
            let currentSelectedSid = state.callerId.selectedNumberSid
            Task {
                do {
                    let response = try await callerIdService.listVerified(serverURL: serverURL)
                    let ids = response.callerIds.map {
                        VerifiedCallerId(
                            id: $0.sid,
                            phoneNumber: $0.phoneNumber,
                            friendlyName: $0.friendlyName,
                            dateCreated: $0.dateCreated
                        )
                    }
                    await MainActor.run {
                        dispatch(.verifiedCallerIdsLoaded(ids))
                        if currentSelectedSid == nil, let first = ids.first {
                            dispatch(.selectCallerId(first.id))
                        }
                    }
                } catch {
                    let appError = (error as? AppError) ?? .networkError(error.localizedDescription)
                    await MainActor.run {
                        dispatch(.callerIdVerificationFailed(appError))
                    }
                }
            }

        case .deleteCallerId(let sid):
            let serverURL = state.serverURL
            let nextSelection = state.callerId.selectedNumberSid == sid
                ? state.callerId.verifiedNumbers.first(where: { $0.id != sid })?.id
                : state.callerId.selectedNumberSid
            Task {
                do {
                    try await callerIdService.delete(sid: sid, serverURL: serverURL)
                    await MainActor.run {
                        dispatch(.callerIdDeleted(sid))
                        dispatch(.selectCallerId(nextSelection))
                    }
                } catch {
                    let appError = (error as? AppError) ?? .networkError(error.localizedDescription)
                    await MainActor.run {
                        dispatch(.callerIdVerificationFailed(appError))
                    }
                }
            }

        case .selectCallerId(let sid):
            if let sid {
                UserDefaults.standard.set(sid, forKey: CallerIdState.selectedCallerIdKey)
            } else {
                UserDefaults.standard.removeObject(forKey: CallerIdState.selectedCallerIdKey)
            }

        default:
            break
        }
    }
}
