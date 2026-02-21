//
//  SettingsView.swift
//  habla-ios
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @State private var agentUserName: String = ""
    @State private var isPresentingAddCallerId = false

    private var state: AppState { store.state }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Agent section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Agent Mode")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                            .textCase(.uppercase)

                        Text("Your Name")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.appTextSecondary)

                        TextField("Maxim", text: $agentUserName)
                            .font(.system(size: 16))
                            .foregroundColor(.appTextPrimary)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.appSurface)
                            )
                            .onChange(of: agentUserName) { _, newValue in
                                store.dispatch(.agentUserNameChanged(newValue))
                                UserDefaults.standard.set(newValue, forKey: "agentUserName")
                            }
                    }

                    Divider()
                        .background(Color.appSurface)

                    // Translation section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Translation")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                            .textCase(.uppercase)

                        Text("Choose the language you speak and the language the other person speaks.")
                            .font(.system(size: 13))
                            .foregroundColor(.appTextSecondary)

                        languagePickerRow(
                            title: "I speak",
                            selectedCode: state.translationSourceLanguage,
                            onSelect: { code in
                                store.dispatch(.translationSourceLanguageChanged(code))
                            }
                        )

                        languagePickerRow(
                            title: "They speak",
                            selectedCode: state.translationTargetLanguage,
                            onSelect: { code in
                                store.dispatch(.translationTargetLanguageChanged(code))
                            }
                        )
                    }

                    Divider()
                        .background(Color.appSurface)

                    // Caller ID section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Caller ID")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                            .textCase(.uppercase)

                        Text("Your phone number")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.appTextSecondary)

                        Text("When set, call recipients see your real number instead of an unknown number.")
                            .font(.system(size: 13))
                            .foregroundColor(.appTextSecondary)

                        callerIdListSection

                        Button {
                            isPresentingAddCallerId = true
                        } label: {
                            Text("+ Add new number")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.appAccent)
                        }
                    }

                    Divider()
                        .background(Color.appSurface)

                    // About section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                            .textCase(.uppercase)

                        VStack(alignment: .leading, spacing: 8) {
                            aboutRow(title: "App", value: "Habla v1.0.0")
                            aboutRow(title: "Purpose", value: "Real-time phone call translation")
                            aboutRow(
                                title: "Translation",
                                value: "\(TranslationLanguageCatalog.languageLabel(for: state.translationSourceLanguage)) <-> \(TranslationLanguageCatalog.languageLabel(for: state.translationTargetLanguage))"
                            )
                            aboutRow(title: "Powered by", value: "Amazon Nova 2 Sonic")
                            aboutRow(title: "Built for", value: "Amazon Nova AI Hackathon")
                        }
                    }
                }
                .padding(20)
            }

            Spacer()
        }
        .background(Color.appBackground)
        .onAppear {
            agentUserName = state.agentUserName
            store.dispatch(.loadVerifiedCallerIds)
        }
        .sheet(isPresented: $isPresentingAddCallerId) {
            CallerIdSettingsView()
                .environmentObject(store)
        }
    }

    private func languagePickerRow(
        title: String,
        selectedCode: String,
        onSelect: @escaping (String) -> Void
    ) -> some View {
        Menu {
            ForEach(TranslationLanguageCatalog.languages) { language in
                Button(language.label) {
                    onSelect(language.code)
                }
            }
        } label: {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appTextSecondary)

                Spacer()

                Text(TranslationLanguageCatalog.languageLabel(for: selectedCode))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appTextPrimary)

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.appTextSecondary)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.appSurface))
        }
    }

    private func aboutRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.appTextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundColor(.appTextPrimary)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var callerIdListSection: some View {
        if state.callerId.isLoading && state.callerId.verifiedNumbers.isEmpty {
            ProgressView()
                .tint(.appAccent)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(spacing: 8) {
                ForEach(state.callerId.verifiedNumbers) { callerId in
                    HStack(spacing: 10) {
                        Image(systemName: state.callerId.selectedNumberSid == callerId.id ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(state.callerId.selectedNumberSid == callerId.id ? .green : .appTextSecondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(callerId.phoneNumber)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.appTextPrimary)
                            if let friendlyName = callerId.friendlyName, !friendlyName.isEmpty {
                                Text(friendlyName)
                                    .font(.system(size: 13))
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                        Spacer()
                        Button(role: .destructive) {
                            store.dispatch(.deleteCallerId(callerId.id))
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.appSurface))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        store.dispatch(.selectCallerId(callerId.id))
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            store.dispatch(.deleteCallerId(callerId.id))
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                Button {
                    store.dispatch(.selectCallerId(nil))
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: state.callerId.selectedNumberSid == nil ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(state.callerId.selectedNumberSid == nil ? .green : .appTextSecondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Use Twilio number")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.appTextPrimary)
                            Text("Default outbound caller ID")
                                .font(.system(size: 13))
                                .foregroundColor(.appTextSecondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.appSurface))
                }
            }
        }

        if let error = state.callerId.error {
            HStack(alignment: .top, spacing: 8) {
                Text(error.localizedDescription)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                Spacer()
                Button("Clear") {
                    store.dispatch(.clearCallerIdError)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.appTextSecondary)
            }
        }
    }
}
