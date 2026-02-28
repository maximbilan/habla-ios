import SwiftUI

struct CriticalConfirmationBanner: View {
    let confirmation: CriticalConfirmation
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text("Confirm Critical Detail")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.appTextSecondary)
                }
            }

            Text(confirmation.promptEn)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.appTextPrimary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.appSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.appAgentAccent.opacity(0.35), lineWidth: 1)
        )
    }
}

struct VerifiedFactsSummaryCard: View {
    let title: String
    let facts: [VerifiedFact]
    var maxItems: Int = 4
    var showOnlyVerifiedWhenAvailable: Bool = true

    private var visibleFacts: [VerifiedFact] {
        let verified = facts.filter { $0.verified }
        let source: [VerifiedFact]
        if showOnlyVerifiedWhenAvailable {
            source = verified.isEmpty ? facts : verified
        } else {
            source = facts
        }
        return Array(source.prefix(maxItems))
    }

    var body: some View {
        if !visibleFacts.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appTextPrimary)

                ForEach(visibleFacts) { fact in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(fact.displayType)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                            .frame(width: 64, alignment: .leading)

                        Text(fact.value)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.appTextPrimary)
                            .lineLimit(2)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.appSurface)
            )
        }
    }
}

struct GoalProgressCard: View {
    let progress: GoalProgressPayload

    private var completionText: String {
        "\(Int((progress.completionRate * 100).rounded()))%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Goal Progress")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Text(completionText)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(progress.success ? .green : .appTextSecondary)
            }

            if !progress.objective.isEmpty {
                Text(progress.objective)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appTextPrimary)
            }

            if !progress.fields.isEmpty {
                ForEach(progress.fields) { field in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(field.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                            .frame(width: 88, alignment: .leading)

                        Text(field.value)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.appTextPrimary)
                            .lineLimit(2)
                    }
                }
            }

            if !progress.missingFields.isEmpty {
                Text("Missing: \(progress.missingFields.map(formatGoalFieldName).joined(separator: ", "))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appTextSecondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.appSurface)
        )
    }
}

struct GoalResultCompactCard: View {
    let result: GoalResultSummary

    private var statusText: String {
        result.success ? "Goal completed" : "Goal partially completed"
    }

    private var statusColor: Color {
        result.success ? .green : .orange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Result")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Text(statusText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(statusColor)
            }

            if !result.summaryEn.isEmpty {
                Text(result.summaryEn)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appTextPrimary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.appSurface)
        )
    }
}

private func formatGoalFieldName(_ fieldName: String) -> String {
    switch fieldName {
    case "next_step":
        return "next step"
    case "phone_number":
        return "phone number"
    default:
        return fieldName.replacingOccurrences(of: "_", with: " ")
    }
}
