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
    private var canBackspace: Bool {
        state.phoneNumber.count > selectedCountry.dialCode.count
    }
    private var matchedCallerMemory: CallerMemory? {
        guard let phoneKey = CallerMemoryKey.normalize(phoneNumber: state.phoneNumber),
              let activePhoneKey = state.activeCallerMemoryPhoneKey,
              phoneKey == activePhoneKey,
              let memory = state.activeCallerMemory,
              memory.consentGranted else {
            return nil
        }
        return memory
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics = DialerLayoutMetrics(container: proxy.size)

            VStack(spacing: 0) {
                Spacer(minLength: metrics.outerSpacerMin)

                VStack(spacing: metrics.sectionSpacing) {
                    VStack(spacing: metrics.titleSpacing) {
                        Text("Habla")
                            .font(.system(size: metrics.titleFontSize, weight: .bold, design: .rounded))
                            .foregroundColor(.appAccent)
                        if !metrics.hideSubtitle {
                            Text("Say it in yours. Hear it in theirs.")
                                .font(.system(size: metrics.subtitleFontSize, weight: .medium))
                                .foregroundColor(.appTextSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                    }

                    if let memory = matchedCallerMemory {
                        CallerMemoryPreviewCard(memory: memory)
                    }

                    Menu {
                        ForEach(PhoneCountryCatalog.countries) { country in
                            Button(country.label) {
                                store.dispatch(.dialCountryChanged(country.isoCode))
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("\(selectedCountry.flagEmoji) \(selectedCountry.name)")
                                .font(.system(size: metrics.countryFontSize, weight: .medium))
                            Text(selectedCountry.dialCode)
                                .font(.system(size: metrics.countryFontSize, weight: .semibold, design: .monospaced))
                            Image(systemName: "chevron.down")
                                .font(.system(size: metrics.chevronFontSize, weight: .semibold))
                        }
                        .foregroundColor(.appTextSecondary)
                        .padding(.horizontal, metrics.countryHorizontalPadding)
                        .padding(.vertical, metrics.countryVerticalPadding)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.appSurface)
                        )
                    }

                    Group {
                        if let selectedSid = state.callerId.selectedNumberSid,
                           let verified = state.callerId.verifiedNumbers.first(where: { $0.id == selectedSid }) {
                            HStack(spacing: 6) {
                                Text("Calling as:")
                                    .font(.system(size: metrics.callerIdFontSize, weight: .medium))
                                    .foregroundColor(.appTextSecondary)
                                Text(verified.phoneNumber)
                                    .font(.system(size: metrics.callerIdFontSize, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.appTextPrimary)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: metrics.callerIdFontSize))
                                    .foregroundColor(.green)
                            }
                        } else {
                            Text("Calling as: Twilio number")
                                .font(.system(size: metrics.callerIdFontSize, weight: .medium))
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                    ZStack {
                        Text(state.phoneNumber)
                            .font(.system(size: metrics.phoneFontSize, weight: .light, design: .monospaced))
                            .foregroundColor(.appTextPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                            .padding(.leading, metrics.phoneTextSidePadding)
                            .padding(.trailing, metrics.phoneTextSidePadding)

                        HStack {
                            Spacer()
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                store.dispatch(.dialpadBackspace)
                            } label: {
                                Image(systemName: "delete.backward.fill")
                                    .font(.system(size: metrics.phoneDeleteIconSize, weight: .semibold))
                                    .foregroundColor(.appTextSecondary)
                                    .frame(width: metrics.phoneDeleteButtonSize, height: metrics.phoneDeleteButtonSize)
                                    .background(
                                        Circle()
                                            .fill(Color.appKeypad)
                                    )
                            }
                            .opacity(canBackspace ? 1.0 : 0.45)
                            .disabled(!canBackspace)
                        }
                        .padding(.trailing, metrics.phoneDeleteTrailingPadding)
                    }
                    .frame(maxWidth: .infinity)

                    KeypadView(
                        onDigit: { digit in
                            store.dispatch(.dialpadDigitPressed(digit))
                        },
                        buttonSize: metrics.keypadButtonSize,
                        rowSpacing: metrics.keypadRowSpacing,
                        columnSpacing: metrics.keypadColumnSpacing,
                        digitFontSize: metrics.keypadDigitFontSize,
                        lettersFontSize: metrics.keypadLettersFontSize
                    )

                    HStack(spacing: metrics.actionSpacing) {
                        CallButton(
                            isActive: canStartCall,
                            size: metrics.callButtonSize,
                            iconSize: metrics.callButtonIconSize
                        ) {
                            store.dispatch(.initiateCall(to: state.phoneNumber))
                        }

                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            store.dispatch(.navigateTo(.agentSetup))
                        } label: {
                            Text("🤖 Agent")
                                .font(.system(size: metrics.agentButtonFontSize, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: metrics.agentButtonWidth, height: metrics.agentButtonHeight)
                                .background(
                                    RoundedRectangle(cornerRadius: metrics.agentButtonCornerRadius, style: .continuous)
                                        .fill(Color.appAgentAccent)
                                )
                                .opacity(canStartCall ? 1.0 : 0.5)
                        }
                        .disabled(!canStartCall)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, metrics.horizontalPadding)

                Spacer(minLength: metrics.outerSpacerMin)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.appBackground)
    }
}

private struct CallerMemoryPreviewCard: View {
    let memory: CallerMemory

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Caller Memory")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.appTextPrimary)

            if let language = memory.preferredTargetLanguage {
                Text("Language: \(TranslationLanguageCatalog.languageLabelWithEmoji(for: language))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appTextSecondary)
            }

            Text("Tone: \(memory.preferredTone.title)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.appTextSecondary)

            if !memory.priorIssues.isEmpty {
                Text("Prior issues: \(memory.priorIssues)")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.appSurface)
        )
    }
}

private struct DialerLayoutMetrics {
    let horizontalPadding: CGFloat
    let outerSpacerMin: CGFloat
    let sectionSpacing: CGFloat
    let titleSpacing: CGFloat
    let hideSubtitle: Bool
    let titleFontSize: CGFloat
    let subtitleFontSize: CGFloat
    let countryFontSize: CGFloat
    let callerIdFontSize: CGFloat
    let chevronFontSize: CGFloat
    let countryHorizontalPadding: CGFloat
    let countryVerticalPadding: CGFloat
    let phoneFontSize: CGFloat
    let phoneDeleteButtonSize: CGFloat
    let phoneDeleteIconSize: CGFloat
    let phoneDeleteTrailingPadding: CGFloat
    let phoneTextSidePadding: CGFloat
    let keypadButtonSize: CGFloat
    let keypadRowSpacing: CGFloat
    let keypadColumnSpacing: CGFloat
    let keypadDigitFontSize: CGFloat
    let keypadLettersFontSize: CGFloat
    let actionSpacing: CGFloat
    let callButtonSize: CGFloat
    let callButtonIconSize: CGFloat
    let agentButtonWidth: CGFloat
    let agentButtonHeight: CGFloat
    let agentButtonCornerRadius: CGFloat
    let agentButtonFontSize: CGFloat

    init(container: CGSize) {
        let compactHeight = container.height < 700
        let veryShortHeight = container.height < 620
        let compactWidth = container.width < 360
        let compactScale = max(0.88, min(1.0, container.height / 590))
        let regularScale = max(0.95, min(1.0, container.height / 760))
        let scale = compactHeight ? compactScale : regularScale

        horizontalPadding = compactWidth ? 10 : 12
        outerSpacerMin = veryShortHeight ? 2 : (compactHeight ? 6 : 10)
        sectionSpacing = (compactHeight ? 12 : 14) * scale
        titleSpacing = compactHeight ? 3 : 4
        hideSubtitle = veryShortHeight

        titleFontSize = (compactHeight ? 34 : 36) * scale
        subtitleFontSize = (compactHeight ? 13 : 14) * scale
        countryFontSize = (compactHeight ? 14 : 14) * scale
        callerIdFontSize = (compactHeight ? 12 : 13) * scale
        chevronFontSize = 11 * scale
        countryHorizontalPadding = (compactHeight ? 10 : 12) * scale
        countryVerticalPadding = (compactHeight ? 7 : 8) * scale

        phoneFontSize = (compactHeight ? 30 : 32) * scale
        phoneDeleteButtonSize = (compactHeight ? 44 : 46) * scale
        phoneDeleteIconSize = (compactHeight ? 18 : 20) * scale
        phoneDeleteTrailingPadding = compactWidth ? 4 : 8
        phoneTextSidePadding = (compactWidth ? 12 : 18) + phoneDeleteButtonSize + phoneDeleteTrailingPadding

        keypadButtonSize = (compactHeight ? 68 : 72) * scale
        keypadRowSpacing = (compactHeight ? 14 : 16) * scale
        keypadColumnSpacing = (compactHeight ? 20 : 24) * scale
        keypadDigitFontSize = (compactHeight ? 26 : 28) * scale
        keypadLettersFontSize = (compactHeight ? 9 : 10) * scale

        actionSpacing = (compactHeight ? 14 : 18) * scale
        callButtonSize = (compactHeight ? 68 : 72) * scale
        callButtonIconSize = (compactHeight ? 26 : 28) * scale
        agentButtonWidth = (compactWidth ? 124 : 140) * scale
        agentButtonHeight = (compactHeight ? 54 : 56) * scale
        agentButtonCornerRadius = agentButtonHeight / 2
        agentButtonFontSize = (compactHeight ? 17 : 18) * scale
    }
}
