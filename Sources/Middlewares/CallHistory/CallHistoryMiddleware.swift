//
//  CallHistoryMiddleware.swift
//  habla-ios
//

import Foundation
import SwiftData

final class CallHistoryMiddleware: Middleware, @unchecked Sendable {
    private let modelContainer: ModelContainer
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
                    let records = models.prefix(maxStoredRecords).map { $0.toCallRecord() }
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
                        status: record.status
                    )
                    context.insert(model)
                    try context.save()
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
