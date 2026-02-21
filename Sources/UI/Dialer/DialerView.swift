//
//  DialerView.swift
//  habla-ios
//

import SwiftUI

struct DialerView: View {
    @EnvironmentObject var store: Store

    private var state: AppState { store.state }
    private var selectedCountry: PhoneCountry {
        PhoneCountryCatalog.country(isoCode: state.selectedDialCountryCode) ?? PhoneCountryCatalog.defaultCountry
    }
    private var canStartCall: Bool {
        state.phoneNumber.count > selectedCountry.dialCode.count + 3 && state.callStatus == .idle
    }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: 16)

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

            Menu {
                ForEach(PhoneCountryCatalog.countries) { country in
                    Button(country.label) {
                        store.dispatch(.dialCountryChanged(country.isoCode))
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(selectedCountry.name)
                        .font(.system(size: 14, weight: .medium))
                    Text(selectedCountry.dialCode)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.appTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.appSurface)
                )
            }
            .padding(.bottom, 10)

            if let selectedSid = state.callerId.selectedNumberSid,
               let verified = state.callerId.verifiedNumbers.first(where: { $0.id == selectedSid }) {
                HStack(spacing: 6) {
                    Text("Calling as:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                    Text(verified.phoneNumber)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.appTextPrimary)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.green)
                }
                .padding(.bottom, 10)
            } else {
                Text("Calling as: Twilio number")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appTextSecondary)
                    .padding(.bottom, 10)
            }

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
                    isActive: canStartCall
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
                        .opacity(canStartCall ? 1.0 : 0.5)
                }
                .disabled(!canStartCall)
            }
            .padding(.bottom, 20)

            Spacer()
        }
        .background(Color.appBackground)
    }
}
