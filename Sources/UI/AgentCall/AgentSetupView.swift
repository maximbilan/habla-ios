import SwiftUI

struct AgentSetupView: View {
    @EnvironmentObject var store: Store
    @State private var promptText: String = ""
    @State private var userName: String = ""

    private var state: AppState { store.state }
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

    private let suggestions: [AgentPromptSuggestion] = [
        .init(
            title: "Hours & appointments",
            prompt: "Call the business and politely ask for their operating hours, whether appointments are required, and whether walk-ins are accepted. If appointments are required, ask what openings are usually available in the next week."
        ),
        .init(
            title: "Schedule next week",
            prompt: "Call to request an appointment for next week. Ask what documents or information they need from me before confirming the booking, and ask them to repeat the confirmed date and time clearly."
        ),
        .init(
            title: "Pricing details",
            prompt: "Call and ask for full pricing details, including any setup costs, monthly fees, and what is included in each plan. Ask whether there are discounts, promotions, or contract commitments."
        ),
        .init(
            title: "General info & next steps",
            prompt: "Call to request a clear overview of the service and the exact next steps to get started. Ask what I should do first, what information they need from me, and how long the process usually takes."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    store.dispatch(.navigateTo(.dialer))
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.appAgentAccent)
                }

                Spacer()

                Text("Agent Call")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.appTextPrimary)

                Spacer()
                Color.clear.frame(width: 56, height: 1)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Calling: \(state.phoneNumber)")
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundColor(.appTextSecondary)

                    if !state.verifiedFactsSummary.isEmpty {
                        VerifiedFactsSummaryCard(
                            title: "Last Call Verified Facts",
                            facts: state.verifiedFactsSummary,
                            maxItems: 4
                        )
                    }

                    if let memory = matchedCallerMemory {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Caller memory will be applied")
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
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.appSurface)
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your name")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                            .textCase(.uppercase)

                        TextField("Maxim", text: $userName)
                            .font(.system(size: 16))
                            .foregroundColor(.appTextPrimary)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.appSurface))
                            .onChange(of: userName) { _, newValue in
                                store.dispatch(.agentUserNameChanged(newValue))
                                UserDefaults.standard.set(newValue, forKey: "agentUserName")
                            }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("What should the agent say on your behalf?")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                            .textCase(.uppercase)

                        TextEditor(text: $promptText)
                            .font(.system(size: 16))
                            .foregroundColor(.appTextPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 180)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.appSurface))
                            .onChange(of: promptText) { _, newValue in
                                store.dispatch(.agentPromptChanged(newValue))
                            }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick suggestions")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                            .textCase(.uppercase)

                        ForEach(suggestions) { suggestion in
                            Button {
                                promptText = suggestion.prompt
                                store.dispatch(.agentPromptChanged(suggestion.prompt))
                            } label: {
                                Text(suggestion.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.appTextPrimary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.appAgentAccent.opacity(0.18))
                                    )
                            }
                        }
                    }

                    Button {
                        store.dispatch(
                            .initiateAgentCall(
                                to: state.phoneNumber,
                                prompt: promptText.trimmingCharacters(in: .whitespacesAndNewlines),
                                userName: userName.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                        )
                    } label: {
                        Text("🤖 Start Agent Call")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.appAgentAccent)
                            )
                    }
                    .disabled(promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1.0)
                    .padding(.top, 4)
                }
                .padding(20)
            }
        }
        .background(Color.appBackground)
        .onAppear {
            promptText = state.agentPrompt
            userName = state.agentUserName
        }
    }
}

private struct AgentPromptSuggestion: Identifiable {
    let title: String
    let prompt: String

    var id: String { title }
}
