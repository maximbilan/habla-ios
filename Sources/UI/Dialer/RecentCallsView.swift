//
//  RecentCallsView.swift
//  habla-ios
//

import SwiftUI

struct RecentCallsView: View {
    let calls: [CallRecord]
    let onCallTapped: (String) -> Void
    let onSummaryTapped: (CallRecord) -> Void

    var body: some View {
        if calls.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "phone.badge.clock")
                    .font(.system(size: 32))
                    .foregroundColor(.appTextSecondary.opacity(0.5))
                Text("No recent calls")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
            }
            .padding(.top, 20)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(calls) { call in
                        RecentCallRow(
                            call: call,
                            callIcon: callIcon(for: call.status),
                            callColor: callColor(for: call.status),
                            onCallTapped: onCallTapped,
                            onSummaryTapped: onSummaryTapped
                        )

                        Divider()
                            .background(Color.appSurface)
                    }
                }
            }
        }
    }

    private func callIcon(for status: String) -> String {
        switch status {
        case "completed": return "phone.arrow.up.right"
        case "failed": return "phone.down"
        case "missed": return "phone.arrow.down.left"
        default: return "phone"
        }
    }

    private func callColor(for status: String) -> Color {
        switch status {
        case "completed": return .appAccent
        case "failed": return .appDestructive
        case "missed": return .appDestructive
        default: return .appTextSecondary
        }
    }
}

private struct RecentCallRow: View {
    let call: CallRecord
    let callIcon: String
    let callColor: Color
    let onCallTapped: (String) -> Void
    let onSummaryTapped: (CallRecord) -> Void

    private var hasMetaBadges: Bool {
        !call.verifiedFacts.isEmpty || !call.conversation.isEmpty || call.goalResult != nil
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: callIcon)
                .font(.system(size: 14))
                .foregroundColor(callColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Button {
                        onCallTapped(call.phoneNumber)
                    } label: {
                        Text(call.phoneNumber)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.appTextPrimary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 8)

                    Text(call.duration.formattedDuration)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)

                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.appAccent)
                }

                Text(call.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(1)

                if hasMetaBadges {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if !call.verifiedFacts.isEmpty {
                                CallMetaBadge(
                                    text: "\(call.verifiedFacts.count) facts",
                                    foreground: .appAgentAccent,
                                    background: Color.appAgentAccent.opacity(0.14)
                                )
                            }

                            if !call.conversation.isEmpty {
                                CallMetaBadge(
                                    text: "\(call.conversation.count) turns",
                                    foreground: .appTextSecondary,
                                    background: Color.appSurface
                                )
                            }

                            if let goal = call.goalResult {
                                CallMetaBadge(
                                    text: goal.success ? "goal done" : "goal \(Int((goal.completionRate * 100).rounded()))%",
                                    foreground: goal.success ? .green : .orange,
                                    background: (goal.success ? Color.green : Color.orange).opacity(0.14)
                                )
                            }
                        }
                        .padding(.vertical, 1)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            onSummaryTapped(call)
        }
    }
}

private struct CallMetaBadge: View {
    let text: String
    let foreground: Color
    let background: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(foreground)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(background)
            )
    }
}
