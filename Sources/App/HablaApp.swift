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
        let container = Self.makeModelContainer()
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
            CallerIdMiddleware(),
        ]

        _store = StateObject(wrappedValue: Store(middlewares: middlewares))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear {
                    store.dispatch(.loadCallHistory)
                    store.dispatch(.loadVerifiedCallerIds)
                }
        }
    }

    private static func makeModelContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: CallRecordModel.self)
        } catch {
            // Recover from local schema incompatibilities without crashing startup.
            clearDefaultSwiftDataStoreFiles()
            do {
                return try ModelContainer(for: CallRecordModel.self)
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }

    private static func clearDefaultSwiftDataStoreFiles() {
        let fileManager = FileManager.default
        let fileNames = [
            "default.store",
            "default.store-shm",
            "default.store-wal",
            "default.store-journal",
        ]

        let baseDirectories = [
            fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
            fileManager.urls(for: .documentDirectory, in: .userDomainMask).first,
        ].compactMap { $0 }

        var targets: Set<URL> = []
        for base in baseDirectories {
            for name in fileNames {
                targets.insert(base.appendingPathComponent(name))
            }

            if let enumerator = fileManager.enumerator(
                at: base,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) {
                for case let fileURL as URL in enumerator {
                    if fileNames.contains(fileURL.lastPathComponent) {
                        targets.insert(fileURL)
                    }
                }
            }
        }

        for url in targets {
            try? fileManager.removeItem(at: url)
        }
    }
}
