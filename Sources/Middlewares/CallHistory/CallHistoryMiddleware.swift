//
//  CallHistoryMiddleware.swift
//  habla-ios
//

import Foundation
import SwiftData

final class CallHistoryMiddleware: Middleware, @unchecked Sendable {
    private let modelContainer: ModelContainer
    private let conversationArchive = ConversationArchiveStore()
    private let maxStoredRecords = 200
    private let retentionDays = 30

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func process(action: AppAction, state: AppState, dispatch: @escaping @MainActor (AppAction) -> Void) {
        switch action {
        case .loadCallHistory:
            let container = modelContainer
            Task { @MainActor in
                do {
                    let context = container.mainContext
                    try pruneHistory(context: context)
                    let descriptor = FetchDescriptor<CallRecordModel>(
                        sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
                    )
                    let models = try context.fetch(descriptor)
                    let retainedModels = Array(models.prefix(maxStoredRecords))
                    let retainedIds = Set(retainedModels.map(\.id))
                    conversationArchive.prune(excluding: retainedIds)
                    let records = retainedModels.map { model in
                        model.toCallRecord(
                            conversation: conversationArchive.loadConversation(for: model.id)
                        )
                    }
                    dispatch(.callHistoryLoaded(records))
                } catch {
                    // Keep call UI responsive even if persistence fails.
                }
            }

        case .saveCallRecord(let record):
            let container = modelContainer
            Task { @MainActor in
                do {
                    let context = container.mainContext
                    let model = CallRecordModel(
                        id: record.id,
                        phoneNumber: record.phoneNumber,
                        startedAt: record.startedAt,
                        duration: record.duration,
                        status: record.status,
                        verifiedFactsData: CallRecordModel.encodeVerifiedFacts(record.verifiedFacts)
                    )
                    context.insert(model)
                    try context.save()
                    try? conversationArchive.saveConversation(record.conversation, for: record.id)
                    dispatch(.loadCallHistory)
                } catch {
                    // Keep call UI responsive even if persistence fails.
                }
            }

        default:
            break
        }
    }

    @MainActor
    private func pruneHistory(context: ModelContext) throws {
        let descriptor = FetchDescriptor<CallRecordModel>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        let models = try context.fetch(descriptor)
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? .distantPast

        var deleted = false
        for (index, model) in models.enumerated() {
            let isExpired = model.startedAt < cutoffDate
            let exceedsMax = index >= maxStoredRecords
            if isExpired || exceedsMax {
                context.delete(model)
                deleted = true
            }
        }

        if deleted {
            try context.save()
        }
    }
}

private final class ConversationArchiveStore: @unchecked Sendable {
    private let directoryURL: URL?
    private let fileManager = FileManager.default

    init() {
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            directoryURL = nil
            return
        }

        let targetDirectory = appSupportURL.appendingPathComponent("call-conversations", isDirectory: true)
        do {
            try fileManager.createDirectory(at: targetDirectory, withIntermediateDirectories: true)
            directoryURL = targetDirectory
        } catch {
            directoryURL = nil
        }
    }

    func loadConversation(for callID: UUID) -> [ConversationTurn] {
        guard let fileURL = fileURL(for: callID),
              let data = try? Data(contentsOf: fileURL) else {
            return []
        }

        return (try? JSONDecoder().decode([ConversationTurn].self, from: data)) ?? []
    }

    func saveConversation(_ conversation: [ConversationTurn], for callID: UUID) throws {
        guard let fileURL = fileURL(for: callID) else { return }

        if conversation.isEmpty {
            try? fileManager.removeItem(at: fileURL)
            return
        }

        let data = try JSONEncoder().encode(conversation)
        try data.write(to: fileURL, options: .atomic)
    }

    func prune(excluding retainedCallIDs: Set<UUID>) {
        guard let directoryURL else { return }
        guard let fileURLs = try? fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil
        ) else {
            return
        }

        for fileURL in fileURLs where fileURL.pathExtension == "json" {
            let rawName = fileURL.deletingPathExtension().lastPathComponent
            guard let id = UUID(uuidString: rawName) else {
                try? fileManager.removeItem(at: fileURL)
                continue
            }

            if !retainedCallIDs.contains(id) {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }

    private func fileURL(for callID: UUID) -> URL? {
        directoryURL?.appendingPathComponent("\(callID.uuidString).json")
    }
}
