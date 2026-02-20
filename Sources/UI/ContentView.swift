//
//  ContentView.swift
//  habla-ios
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: Store

    private var state: AppState { store.state }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            Group {
                switch state.activeScreen {
                case .dialer:
                    DialerView()
                        .transition(.move(edge: .leading))
                case .activeCall:
                    ActiveCallView()
                        .transition(.move(edge: .trailing))
                case .agentSetup:
                    AgentSetupView()
                        .transition(.move(edge: .trailing))
                case .agentCall:
                    AgentCallView()
                        .transition(.move(edge: .trailing))
                case .settings:
                    SettingsView()
                        .transition(.move(edge: .trailing))
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
