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
                        HStack(spacing: 12) {
                            Image(systemName: callIcon(for: call.status))
                                .font(.system(size: 14))
                                .foregroundColor(callColor(for: call.status))
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Button {
                                    onCallTapped(call.phoneNumber)
                                } label: {
                                    Text(call.phoneNumber)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.appTextPrimary)
                                }
                                .buttonStyle(.plain)

                                Text(call.startedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 12))
                                    .foregroundColor(.appTextSecondary)
                            }

                            Spacer()

                            HStack(spacing: 10) {
                                Text(call.duration.formattedDuration)
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(.appTextSecondary)

                                if !call.verifiedFacts.isEmpty {
                                    Text("\(call.verifiedFacts.count) facts")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.appAgentAccent)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.appAgentAccent.opacity(0.14))
                                        )
                                }

                                if !call.conversation.isEmpty {
                                    Text("\(call.conversation.count) turns")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.appTextSecondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.appSurface)
                                        )
                                }

                                Button {
                                    onSummaryTapped(call)
                                } label: {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.appAccent)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSummaryTapped(call)
                        }

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
