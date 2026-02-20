import SwiftUI

struct TranscriptBubbleView: View {
    let entry: TranscriptEntry

    var body: some View {
        HStack {
            if entry.role == .callee { Spacer(minLength: 48) }

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.role == .agent ? "🤖 Agent" : "📞 Caller")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)

                Text(entry.textEs)
                    .font(.body)
                    .foregroundColor(.appTextPrimary)

                if let textEn = entry.textEn, !textEn.isEmpty {
                    Text(textEn)
                        .font(.body)
                        .foregroundColor(.appTextSecondary)
                        .italic()
                } else {
                    Text("Translating...")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                        .redacted(reason: .placeholder)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(entry.role == .agent ? Color.appAgentAccent.opacity(0.18) : Color.gray.opacity(0.18))
            )

            if entry.role == .agent { Spacer(minLength: 48) }
        }
    }
}
