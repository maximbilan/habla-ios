import Foundation

final class CallerMemoryMiddleware: Middleware, @unchecked Sendable {
    private let store: CallerMemoryStore

    init(store: CallerMemoryStore = CallerMemoryStore()) {
        self.store = store
    }

    func process(action: AppAction, state: AppState, dispatch: @escaping @MainActor (AppAction) -> Void) {
        switch action {
        case .phoneNumberChanged(let number):
            loadMemory(for: number, dispatch: dispatch)

        case .openCallSummary(let record):
            loadMemory(for: record.phoneNumber, dispatch: dispatch)

        case .navigateTo(let screen):
            if screen == .dialer || screen == .agentSetup {
                loadMemory(for: state.phoneNumber, dispatch: dispatch)
            }

        case .saveCallerMemory(let draft):
            saveMemory(draft: draft, dispatch: dispatch)

        case .saveCallRecord(let record):
            updateCallStats(from: record, dispatch: dispatch)

        default:
            break
        }
    }

    private func loadMemory(for phoneNumber: String, dispatch: @escaping @MainActor (AppAction) -> Void) {
        guard let phoneKey = CallerMemoryKey.normalize(phoneNumber: phoneNumber) else {
            Task { @MainActor in
                dispatch(.callerMemoryLoaded(phoneKey: "", memory: nil))
            }
            return
        }

        Task {
            let memory = await store.memory(for: phoneKey)
            await MainActor.run {
                dispatch(.callerMemoryLoaded(phoneKey: phoneKey, memory: memory))
            }
        }
    }

    private func saveMemory(draft: CallerMemoryDraft, dispatch: @escaping @MainActor (AppAction) -> Void) {
        guard let phoneKey = CallerMemoryKey.normalize(phoneNumber: draft.phoneNumber) else { return }

        Task {
            if !draft.consentGranted {
                await store.deleteMemory(for: phoneKey)
                await MainActor.run {
                    dispatch(.callerMemoryLoaded(phoneKey: phoneKey, memory: nil))
                }
                return
            }

            let existing = await store.memory(for: phoneKey)
            var memory = existing ?? CallerMemory(
                phoneKey: phoneKey,
                phoneNumber: draft.phoneNumber,
                consentGranted: true,
                preferredTargetLanguage: nil,
                preferredTone: .neutral,
                priorIssues: "",
                callCount: 1,
                lastCallAt: Date(),
                updatedAt: Date()
            )

            memory.consentGranted = true
            memory.preferredTargetLanguage = normalizedLanguageCode(draft.preferredTargetLanguage)
            memory.preferredTone = draft.preferredTone
            memory.priorIssues = draft.priorIssues.trimmingCharacters(in: .whitespacesAndNewlines)
            memory.updatedAt = Date()

            await store.saveMemory(memory)
            await MainActor.run {
                dispatch(.callerMemoryLoaded(phoneKey: phoneKey, memory: memory))
            }
        }
    }

    private func updateCallStats(from record: CallRecord, dispatch: @escaping @MainActor (AppAction) -> Void) {
        guard let phoneKey = CallerMemoryKey.normalize(phoneNumber: record.phoneNumber) else { return }

        Task {
            guard var memory = await store.memory(for: phoneKey), memory.consentGranted else { return }
            memory.callCount += 1
            memory.lastCallAt = record.startedAt
            memory.updatedAt = Date()
            await store.saveMemory(memory)
            await MainActor.run {
                dispatch(.callerMemoryLoaded(phoneKey: phoneKey, memory: memory))
            }
        }
    }

    private func normalizedLanguageCode(_ raw: String?) -> String? {
        guard let raw,
              let language = TranslationLanguageCatalog.language(code: raw) else {
            return nil
        }
        return language.code
    }
}

actor CallerMemoryStore {
    private let fileURL: URL?
    private let fileManager: FileManager
    private var cache: [String: CallerMemory]? = nil

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fileURL = nil
            return
        }

        let directoryURL = appSupportURL.appendingPathComponent("caller-memory", isDirectory: true)
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            fileURL = directoryURL.appendingPathComponent("memories.json")
        } catch {
            fileURL = nil
        }
    }

    func memory(for phoneKey: String) -> CallerMemory? {
        loadCacheIfNeeded()
        return cache?[phoneKey]
    }

    func saveMemory(_ memory: CallerMemory) {
        loadCacheIfNeeded()
        cache?[memory.phoneKey] = memory
        persistCache()
    }

    func deleteMemory(for phoneKey: String) {
        loadCacheIfNeeded()
        cache?.removeValue(forKey: phoneKey)
        persistCache()
    }

    private func loadCacheIfNeeded() {
        guard cache == nil else { return }
        guard let fileURL else {
            cache = [:]
            return
        }
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: CallerMemory].self, from: data) else {
            cache = [:]
            return
        }
        cache = decoded
    }

    private func persistCache() {
        guard let fileURL,
              let cache,
              let data = try? JSONEncoder().encode(cache) else {
            return
        }
        try? data.write(to: fileURL, options: .atomic)
    }
}
