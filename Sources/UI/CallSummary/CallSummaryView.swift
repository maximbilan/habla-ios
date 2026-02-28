import SwiftUI

struct CallSummaryView: View {
    @EnvironmentObject var store: Store

    private var state: AppState { store.state }
    private var call: CallRecord? { state.selectedCallSummaryRecord }
    private var facts: [VerifiedFact] {
        call?.verifiedFacts.isEmpty == false ? (call?.verifiedFacts ?? []) : state.verifiedFactsSummary
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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
        }
        .background(Color.appBackground)
    }
}
