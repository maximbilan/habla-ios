//
//  SettingsView.swift
//  habla-ios
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @State private var agentUserName: String = ""

    private var state: AppState { store.state }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Agent section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Agent Mode")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                            .textCase(.uppercase)

                        Text("Your Name")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.appTextSecondary)

                        TextField("Maxim", text: $agentUserName)
                            .font(.system(size: 16))
                            .foregroundColor(.appTextPrimary)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.appSurface)
                            )
                            .onChange(of: agentUserName) { _, newValue in
                                store.dispatch(.agentUserNameChanged(newValue))
                                UserDefaults.standard.set(newValue, forKey: "agentUserName")
                            }
                    }

                    Divider()
                        .background(Color.appSurface)

                    // About section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                            .textCase(.uppercase)

                        VStack(alignment: .leading, spacing: 8) {
                            aboutRow(title: "App", value: "Habla v1.0.0")
                            aboutRow(title: "Purpose", value: "Real-time phone call translation")
                            aboutRow(title: "Translation", value: "English ↔ Spanish")
                            aboutRow(title: "Powered by", value: "Amazon Nova 2 Sonic")
                            aboutRow(title: "Built for", value: "Amazon Nova AI Hackathon")
                        }
                    }
                }
                .padding(20)
            }

            Spacer()
        }
        .background(Color.appBackground)
        .onAppear {
            agentUserName = state.agentUserName
        }
    }

    private func aboutRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.appTextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundColor(.appTextPrimary)
        }
        .padding(.vertical, 4)
    }
}
