//
//  SettingsView.swift
//  habla-ios
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @State private var serverURL: String = ""

    private var state: AppState { store.state }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    store.dispatch(.navigateTo(.dialer))
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.appAccent)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Server URL section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Server URL")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                            .textCase(.uppercase)

                        TextField("http://localhost:8000", text: $serverURL)
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundColor(.appTextPrimary)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.appSurface)
                            )
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .onSubmit {
                                store.dispatch(.serverURLChanged(serverURL))
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
            serverURL = state.serverURL
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
