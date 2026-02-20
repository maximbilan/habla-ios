import SwiftUI

struct AgentSetupView: View {
    @EnvironmentObject var store: Store
    @State private var promptText: String = ""
    @State private var userName: String = ""

    private var state: AppState { store.state }

    private let suggestions: [String] = [
        "Ask about business hours and whether appointments are required.",
        "Schedule an appointment for next week and ask what documents I need.",
        "Ask about pricing and monthly fees.",
        "Request general information and next steps.",
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

                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                promptText = suggestion
                                store.dispatch(.agentPromptChanged(suggestion))
                            } label: {
                                Text(suggestion)
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
                        store.dispatch(.setCallMode(.agent))
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
