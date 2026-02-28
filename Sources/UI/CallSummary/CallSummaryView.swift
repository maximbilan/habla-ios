import SwiftUI

struct CallSummaryView: View {
    @EnvironmentObject var store: Store

    private var state: AppState { store.state }
    private var call: CallRecord? { state.selectedCallSummaryRecord }
    private var facts: [VerifiedFact] {
        call?.verifiedFacts.isEmpty == false ? (call?.verifiedFacts ?? []) : state.verifiedFactsSummary
    }
    private var conversation: [ConversationTurn] {
        (call?.conversation ?? []).sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    store.dispatch(.closeCallSummary)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Done")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appAccent)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Post-Call Summary")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.appTextPrimary)

                    if let call {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(call.phoneNumber)
                                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                                .foregroundColor(.appTextPrimary)
                            Text(call.startedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.appTextSecondary)
                            Text("Duration: \(call.duration.formattedDuration)")
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(.appTextSecondary)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.appSurface)
                        )
                    }

                    VerifiedFactsSummaryCard(
                        title: "Verified Facts",
                        facts: facts,
                        maxItems: max(6, facts.count),
                        showOnlyVerifiedWhenAvailable: false
                    )

                    if facts.isEmpty {
                        Text("No critical facts were captured for this call.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                            .padding(.top, 6)
                    }

                    if !conversation.isEmpty {
                        Text("Conversation")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.appTextPrimary)
                            .padding(.top, 6)

                        LazyVStack(spacing: 10) {
                            ForEach(conversation) { turn in
                                ConversationTurnBubbleView(turn: turn)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
        }
        .background(Color.appBackground)
    }
}

private struct ConversationTurnBubbleView: View {
    let turn: ConversationTurn

    var body: some View {
        HStack {
            if turn.role.alignsRight { Spacer(minLength: 48) }

            VStack(alignment: .leading, spacing: 6) {
                Text(turn.role.title)
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)

                Text(turn.text)
                    .font(.body)
                    .foregroundColor(.appTextPrimary)

                if let translated = displayedTranslation {
                    Text(translated)
                        .font(.body)
                        .foregroundColor(.appTextSecondary)
                        .italic()
                }

                Text(turn.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.appTextSecondary.opacity(0.8))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(bubbleColor)
            )

            if !turn.role.alignsRight { Spacer(minLength: 48) }
        }
    }

    private var displayedTranslation: String? {
        guard let translated = turn.translatedText?.trimmingCharacters(in: .whitespacesAndNewlines), !translated.isEmpty else {
            return nil
        }
        if normalized(translated) == normalized(turn.text) {
            return nil
        }
        return translated
    }

    private var bubbleColor: Color {
        switch turn.role {
        case .interpreter, .agent:
            return Color.appAgentAccent.opacity(0.18)
        case .caller, .callee:
            return Color.gray.opacity(0.18)
        }
    }

    private func normalized(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")
            .lowercased()
    }
}
