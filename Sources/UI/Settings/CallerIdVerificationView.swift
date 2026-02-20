import SwiftUI

struct CallerIdVerificationView: View {
    @EnvironmentObject var store: Store
    @Binding var isPresented: Bool
    @State private var autoDismissTask: Task<Void, Never>?

    private var state: AppState { store.state }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            switch state.callerId.verificationStatus {
            case .verified:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.green)
                Text("Number verified!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Button("Done") {
                    isPresented = false
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.appAccent))
                .padding(.horizontal, 24)

            case .failed(let message):
                Image(systemName: "xmark.octagon.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.red)
                Text("Verification failed")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button("Try Again") {
                    store.dispatch(.startCallerIdVerification)
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.appAccent))
                .padding(.horizontal, 24)

            default:
                callingBody
            }

            Button("Cancel") {
                isPresented = false
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.appTextSecondary)

            Spacer()
        }
        .background(Color.appBackground)
        .onChange(of: state.callerId.verificationStatus) { _, newValue in
            if case .verified = newValue {
                autoDismissTask?.cancel()
                autoDismissTask = Task {
                    try? await Task.sleep(for: .seconds(2))
                    if !Task.isCancelled {
                        await MainActor.run {
                            isPresented = false
                        }
                    }
                }
            }
        }
        .onDisappear {
            autoDismissTask?.cancel()
        }
    }

    private var callingBody: some View {
        VStack(spacing: 18) {
            Text("📞 Calling...")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.appTextPrimary)

            Text("Twilio is calling")
                .font(.system(size: 17))
                .foregroundColor(.appTextSecondary)

            Text(state.callerId.phoneNumber)
                .font(.system(size: 22, weight: .semibold, design: .monospaced))
                .foregroundColor(.appTextPrimary)

            if let code = state.callerId.validationCode {
                Text("Answer your phone and enter this code on your keypad:")
                    .font(.system(size: 15))
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text(code.map { String($0) }.joined(separator: " "))
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(.appTextPrimary)
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.appSurface))
                    .padding(.horizontal, 24)

                if state.callerId.isLoading {
                    ProgressView("Checking verification...")
                        .font(.system(size: 15, weight: .medium))
                        .tint(.appAccent)
                }

                Button {
                    store.dispatch(.checkCallerIdStatus)
                } label: {
                    Text("I've entered the code")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.appAccent))
                }
                .disabled(state.callerId.isLoading)
                .opacity(state.callerId.isLoading ? 0.55 : 1.0)
                .padding(.horizontal, 24)
            } else {
                ProgressView("Waiting for verification code...")
                    .font(.system(size: 15, weight: .medium))
                    .tint(.appAccent)
            }
        }
    }
}
