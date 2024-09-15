//
//  EnvironmentValues+.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/3.
//

import SwiftUI

struct ShowErrorEnvironmentKey: EnvironmentKey {
    static var defaultValue: (Error, String) -> Void = { _, _ in }
}

extension EnvironmentValues {
    var showError: (Error, String) -> Void {
        get { self[ShowErrorEnvironmentKey.self] }
        set { self[ShowErrorEnvironmentKey.self] = newValue }
    }
}



struct NavigateEnvironmentKey: EnvironmentKey {
    static var defaultValue: NavigateAction = .init(action: { _ in })
}

extension EnvironmentValues {
    var navigate: NavigateAction {
        get { self[NavigateEnvironmentKey.self] }
        set { self[NavigateEnvironmentKey.self] = newValue }
    }
}

extension View {
    func onNavigate(_ action: @escaping NavigateAction.Action) -> some View {
        environment(\.navigate, NavigateAction(action: action))
    }
}


//struct LoadingEnvironmentKey: EnvironmentKey {
//    static var defaultValue: Bool = false
//}
//
//extension EnvironmentValues {
//    var loading: Bool {
//        get { self[LoadingEnvironmentKey.self] }
//        set { self[LoadingEnvironmentKey.self] = newValue }
//    }
//}
