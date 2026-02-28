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

            Text(confirmation.promptEs)
                .font(.system(size: 13))
                .foregroundColor(.appTextSecondary)
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
