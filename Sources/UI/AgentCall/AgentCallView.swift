import SwiftUI

struct AgentCallView: View {
    @EnvironmentObject var store: Store

    private var state: AppState { store.state }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(state.phoneNumber)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Text(state.callDuration.formattedDuration)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.appTextSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            AgentStatusIndicator(status: state.agentStatus)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let confirmation = state.activeCriticalConfirmation {
                CriticalConfirmationBanner(confirmation: confirmation) {
                    store.dispatch(.clearCriticalConfirmation)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }

            if !state.verifiedFactsSummary.isEmpty {
                VerifiedFactsSummaryCard(
                    title: "Verified Facts",
                    facts: state.verifiedFactsSummary,
                    maxItems: 4
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }

            if let progress = state.agentGoalProgress {
                GoalProgressCard(progress: progress)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }

            if let result = state.agentGoalResult {
                GoalResultCompactCard(result: result)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }

            Divider()
                .background(Color.appSurface)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(state.agentTranscript) { entry in
                            TranscriptBubbleView(entry: entry)
                                .id(entry.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                .onChange(of: state.agentTranscript.count) { _, _ in
                    if let last = state.agentTranscript.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()
                .background(Color.appSurface)

            VStack(spacing: 10) {
                TextField("Add instruction for the agent", text: Binding(
                    get: { state.agentMidCallInput },
                    set: { store.dispatch(.agentMidCallInputChanged($0)) }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .foregroundColor(.appTextPrimary)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.appSurface))

                HStack(spacing: 12) {
                    Button {
                        store.dispatch(.sendAgentInstruction(state.agentMidCallInput))
                    } label: {
                        Text("📤 Send")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.appAgentAccent)
                            )
                    }
                    .disabled(state.agentMidCallInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(state.agentMidCallInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1.0)

                    Button {
                        store.dispatch(.endAgentConversation("Thank them for their help and say goodbye politely."))
                    } label: {
                        Text("🔴 End Call")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.appDestructive)
                            )
                    }
                }
            }
            .padding(12)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}
