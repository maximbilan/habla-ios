//
//  Store.swift
//  habla-ios
//

import Foundation

@MainActor
final class Store: ObservableObject {
    @Published private(set) var state: AppState
    private var middlewares: [Middleware] = []

    init(initialState: AppState = AppState(), middlewares: [Middleware] = []) {
        self.state = initialState
        self.middlewares = middlewares
    }

    func dispatch(_ action: AppAction) {
        #if DEBUG
        print("[Action] \(action)")
        #endif

        for middleware in middlewares {
            middleware.process(action: action, state: state, dispatch: dispatch)
        }
        appReducer(state: &state, action: action)
    }
}
