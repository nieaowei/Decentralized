//
//  EnvironmentValues+.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/3.
//

import SwiftUI

struct ShowErrorEnvironmentKey:@MainActor EnvironmentKey {
    @MainActor static let defaultValue: ShowErrorAction = .init({ _, _ in })
}

struct ShowErrorAction {
    typealias Action = (Error?, String) -> Void
    let action: Action
    
    init(_ action: @escaping Action) {
        self.action = action
    }
    func callAsFunction(_ error: Error?, _ msg: String) {
        action(error, msg)
    }
}

extension EnvironmentValues {
    @MainActor var showError: ShowErrorAction {
        get { self[ShowErrorEnvironmentKey.self] }
        set { self[ShowErrorEnvironmentKey.self] = newValue }
    }
}

struct NavigateEnvironmentKey: @MainActor EnvironmentKey {
    @MainActor static let defaultValue: NavigateAction = .init(action: { _ in })
}

extension EnvironmentValues {
    @MainActor var navigate: NavigateAction {
        get { self[NavigateEnvironmentKey.self] }
        set { self[NavigateEnvironmentKey.self] = newValue }
    }
}

extension View {
    func onNavigate(_ action: @escaping NavigateAction.Action) -> some View {
        environment(\.navigate, NavigateAction(action: action))
    }
    
    func onError(_ action: @escaping ShowErrorAction.Action) -> some View{
        environment(\.showError, ShowErrorAction(action))
    }
}

extension Scene{
    func onError(_ action: @escaping ShowErrorAction.Action) -> some Scene{
        environment(\.showError, ShowErrorAction(action))
    }
}

// struct LoadingEnvironmentKey: EnvironmentKey {
//    static var defaultValue: Bool = false
// }
//
// extension EnvironmentValues {
//    var loading: Bool {
//        get { self[LoadingEnvironmentKey.self] }
//        set { self[LoadingEnvironmentKey.self] = newValue }
//    }
// }
