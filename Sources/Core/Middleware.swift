//
//  Middleware.swift
//  habla-ios
//

protocol Middleware: Sendable {
    func process(action: AppAction, state: AppState, dispatch: @escaping @MainActor (AppAction) -> Void)
}
