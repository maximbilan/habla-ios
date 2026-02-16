//
//  CallHistoryMiddleware.swift
//  habla-ios
//

import Foundation
import SwiftData

final class CallHistoryMiddleware: Middleware, @unchecked Sendable {
    private let modelContainer: ModelContainer

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
                    let descriptor = FetchDescriptor<CallRecordModel>(
                        sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
                    )
                    let models = try context.fetch(descriptor)
                    let records = models.map { $0.toCallRecord() }
                    dispatch(.callHistoryLoaded(records))
                } catch {
                    print("[CallHistoryMiddleware] Load error: \(error)")
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
                    print("[CallHistoryMiddleware] Save error: \(error)")
                }
            }

        default:
            break
        }
    }
}
