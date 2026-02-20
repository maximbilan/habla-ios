//
//  DialerView.swift
//  habla-ios
//

import SwiftUI

struct DialerView: View {
    @EnvironmentObject var store: Store

    private var state: AppState { store.state }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Button {
                    store.dispatch(.navigateTo(.settings))
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 20))
                        .foregroundColor(.appTextSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Spacer()

            // App title
            VStack(spacing: 4) {
                Text("Habla")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.appAccent)
                Text("Say it in yours. Hear it in theirs.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appTextSecondary)
            }
            .padding(.bottom, 24)

            // Phone number display
            Text(state.phoneNumber)
                .font(.system(size: 32, weight: .light, design: .monospaced))
                .foregroundColor(.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 40)
                .padding(.bottom, 24)

            // Keypad
            KeypadView(
                onDigit: { digit in
                    store.dispatch(.dialpadDigitPressed(digit))
                },
                onBackspace: {
                    store.dispatch(.dialpadBackspace)
                }
            )
            .padding(.bottom, 20)

            // Call button
            HStack(spacing: 18) {
                CallButton(
                    isActive: state.phoneNumber.count > 4 && state.callStatus == .idle
                ) {
                    store.dispatch(.setCallMode(.translation))
                    store.dispatch(.initiateCall(to: state.phoneNumber))
                }

                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    store.dispatch(.setCallMode(.agent))
                    store.dispatch(.navigateTo(.agentSetup))
                } label: {
                    Text("🤖 Agent")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 140, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Color.appAgentAccent)
                        )
                        .opacity(state.phoneNumber.count > 4 && state.callStatus == .idle ? 1.0 : 0.5)
                }
                .disabled(!(state.phoneNumber.count > 4 && state.callStatus == .idle))
            }
            .padding(.bottom, 20)

            // Recent calls
            RecentCallsView(
                calls: Array(state.recentCalls.prefix(5)),
                onCallTapped: { number in
                    store.dispatch(.phoneNumberChanged(number))
                }
            )
            .frame(maxHeight: 160)

            Spacer()
        }
        .background(Color.appBackground)
    }
}
