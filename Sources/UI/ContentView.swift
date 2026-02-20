//
//  ContentView.swift
//  habla-ios
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: Store

    private var state: AppState { store.state }
    private var tabSelection: Binding<ActiveScreen> {
        Binding(
            get: {
                switch state.activeScreen {
                case .callHistory:
                    return .callHistory
                case .settings:
                    return .settings
                default:
                    return .dialer
                }
            },
            set: { selected in
                store.dispatch(.navigateTo(selected))
            }
        )
    }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            Group {
                switch state.activeScreen {
                case .activeCall:
                    ActiveCallView()
                        .transition(.move(edge: .trailing))
                case .agentSetup:
                    AgentSetupView()
                        .transition(.move(edge: .trailing))
                case .agentCall:
                    AgentCallView()
                        .transition(.move(edge: .trailing))
                case .dialer, .callHistory, .settings:
                    TabView(selection: tabSelection) {
                        DialerView()
                            .tabItem {
                                Image(systemName: "phone.fill")
                                Text("Phone")
                            }
                            .tag(ActiveScreen.dialer)

                        CallHistoryView()
                            .tabItem {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("History")
                            }
                            .tag(ActiveScreen.callHistory)

                        SettingsView()
                            .tabItem {
                                Image(systemName: "gearshape.fill")
                                Text("Settings")
                            }
                            .tag(ActiveScreen.settings)
                    }
                    .tint(.appAccent)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: state.activeScreen)

            // Error banner overlay
            if let error = state.callError {
                VStack {
                    ErrorBannerView(error: error) {
                        store.dispatch(.clearError)
                    }
                    Spacer()
                }
                .padding(.top, 8)
                .animation(.spring(response: 0.4), value: state.callError)
            }
        }
    }
}
