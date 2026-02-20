//
//  HablaApp.swift
//  habla-ios
//

import SwiftUI
import SwiftData

@main
struct HablaApp: App {
    @StateObject private var store: Store

    let modelContainer: ModelContainer

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: CallRecordModel.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        self.modelContainer = container

        let webSocketService = WebSocketService()
        let agentWebSocketService = AgentWebSocketService()
        let audioService = AudioService()

        let middlewares: [Middleware] = [
            NetworkMiddleware(),
            WebSocketMiddleware(webSocketService: webSocketService, audioService: audioService),
            AudioMiddleware(audioService: audioService, webSocketService: webSocketService),
            CallTimerMiddleware(),
            CallHistoryMiddleware(modelContainer: container),
            AgentNetworkMiddleware(),
            AgentWebSocketMiddleware(webSocketService: agentWebSocketService),
        ]

        _store = StateObject(wrappedValue: Store(middlewares: middlewares))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .onAppear {
                    store.dispatch(.loadCallHistory)
                }
        }
    }
}
