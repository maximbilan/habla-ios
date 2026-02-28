import SwiftUI

struct CallSummaryView: View {
    @EnvironmentObject var store: Store
    @State private var memoryConsent: Bool = false
    @State private var memoryLanguageCode: String = TranslationLanguageCatalog.defaultTarget.code
    @State private var memoryTone: CallerTone = .neutral
    @State private var memoryPriorIssues: String = ""
    @State private var memoryDraftPhoneKey: String = ""
    @State private var memoryDraftEdited: Bool = false

    private var state: AppState { store.state }
    private var call: CallRecord? { state.selectedCallSummaryRecord }
    private var facts: [VerifiedFact] {
        call?.verifiedFacts.isEmpty == false ? (call?.verifiedFacts ?? []) : state.verifiedFactsSummary
    }
    private var goalResult: GoalResultSummary? {
        call?.goalResult ?? state.agentGoalResult
    }
    private var conversation: [ConversationTurn] {
        (call?.conversation ?? []).sorted { $0.timestamp < $1.timestamp }
    }
    private var currentCallPhoneKey: String? {
        guard let phone = call?.phoneNumber else { return nil }
        return CallerMemoryKey.normalize(phoneNumber: phone)
    }
    private var storedMemoryForCurrentCall: CallerMemory? {
        guard let phoneKey = currentCallPhoneKey,
              phoneKey == state.activeCallerMemoryPhoneKey else {
            return nil
        }
        return state.activeCallerMemory
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

                    if let goalResult {
                        GoalResultDetailSection(result: goalResult)
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

                    callerMemorySection

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
        .onAppear {
            if let number = call?.phoneNumber {
                store.dispatch(.loadCallerMemory(number))
            }
            refreshMemoryDraft(force: true)
        }
        .onChange(of: call?.id) { _, _ in
            memoryDraftEdited = false
            if let number = call?.phoneNumber {
                store.dispatch(.loadCallerMemory(number))
            }
            refreshMemoryDraft(force: true)
        }
        .onChange(of: state.activeCallerMemory?.updatedAt) { _, _ in
            refreshMemoryDraft(force: false)
        }
    }

    @ViewBuilder
    private var callerMemorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Caller Memory")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.appTextPrimary)

            Toggle(isOn: Binding(
                get: { memoryConsent },
                set: { newValue in
                    memoryConsent = newValue
                    memoryDraftEdited = true
                }
            )) {
                Text("Consent to remember this caller")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.appTextPrimary)
            }
            .tint(.appAccent)

            if memoryConsent {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preferred language")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                        .textCase(.uppercase)

                    Menu {
                        ForEach(TranslationLanguageCatalog.languages) { language in
                            Button(language.labelWithEmoji) {
                                memoryLanguageCode = language.code
                                memoryDraftEdited = true
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(TranslationLanguageCatalog.languageLabelWithEmoji(for: memoryLanguageCode))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.appTextPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.appTextSecondary)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.appBackground)
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Preferred tone")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                        .textCase(.uppercase)

                    Menu {
                        ForEach(CallerTone.allCases) { tone in
                            Button(tone.title) {
                                memoryTone = tone
                                memoryDraftEdited = true
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(memoryTone.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.appTextPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.appTextSecondary)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.appBackground)
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Prior issues to remember")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                        .textCase(.uppercase)

                    TextEditor(text: Binding(
                        get: { memoryPriorIssues },
                        set: { newValue in
                            memoryPriorIssues = newValue
                            memoryDraftEdited = true
                        }
                    ))
                    .font(.system(size: 15))
                    .foregroundColor(.appTextPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 88)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.appBackground)
                    )
                }
            }

            Button {
                saveCallerMemory()
            } label: {
                Text(memoryConsent ? "Save Caller Memory" : "Disable Caller Memory")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(memoryConsent ? Color.appAccent : Color.appTextSecondary)
                    )
            }

            if let memory = storedMemoryForCurrentCall, memory.consentGranted {
                Text("Saved for \(memory.callCount) call(s). Last seen \(memory.lastCallAt?.formatted(date: .abbreviated, time: .omitted) ?? "today").")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appTextSecondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.appSurface)
        )
    }

    private func refreshMemoryDraft(force: Bool) {
        guard let phoneKey = currentCallPhoneKey else { return }

        if !force && memoryDraftEdited && memoryDraftPhoneKey == phoneKey {
            return
        }

        let memory = storedMemoryForCurrentCall
        let fallbackLanguage = state.translationTargetLanguage

        memoryConsent = memory?.consentGranted ?? false
        memoryLanguageCode = memory?.preferredTargetLanguage ?? fallbackLanguage
        memoryTone = memory?.preferredTone ?? .neutral
        memoryPriorIssues = memory?.priorIssues ?? ""
        memoryDraftPhoneKey = phoneKey
    }

    private func saveCallerMemory() {
        guard let phoneNumber = call?.phoneNumber else { return }
        let draft = CallerMemoryDraft(
            phoneNumber: phoneNumber,
            consentGranted: memoryConsent,
            preferredTargetLanguage: memoryConsent ? memoryLanguageCode : nil,
            preferredTone: memoryTone,
            priorIssues: memoryConsent ? memoryPriorIssues : ""
        )
        store.dispatch(.saveCallerMemory(draft))
        memoryDraftEdited = false
    }
}

private struct GoalResultDetailSection: View {
    let result: GoalResultSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Goal Result")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Text(result.success ? "Completed" : "Partial")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(result.success ? .green : .orange)
            }

            if !result.objective.isEmpty {
                Text(result.objective)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appTextPrimary)
            }

            if !result.fields.isEmpty {
                ForEach(result.fields) { field in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(field.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                            .frame(width: 92, alignment: .leading)
                        Text(field.value)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.appTextPrimary)
                            .lineLimit(3)
                    }
                }
            }

            if !result.missingFields.isEmpty {
                Text("Missing: \(missingFieldsText)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appTextSecondary)
            }

            if !result.summaryEn.isEmpty {
                Text(result.summaryEn)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appTextPrimary)
                    .padding(.top, 2)
            }

            if !result.summaryEs.isEmpty {
                Text(result.summaryEs)
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.appSurface)
        )
    }

    private var missingFieldsText: String {
        result.missingFields
            .map { $0.replacingOccurrences(of: "_", with: " ") }
            .joined(separator: ", ")
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
