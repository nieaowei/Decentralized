//
//  Navigation.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/4.
//

import Foundation
import SwiftUI

struct NavigateAction {
    typealias Action = (NavigationType) -> ()
    let action: Action
    func callAsFunction(_ navigationType: NavigationType) {
        action(navigationType)
    }
}

enum Route: Hashable {
    case wallet(WalletRoute)
    case tools(ToolRoute)

    var title: String {
        switch self {
        case .wallet:
            "Wallet"
        case .tools:
            "Tools"
        }
    }

    static var allCases: [Route] {
        [.wallet(.me), .tools(.broadcast)]
    }
}
//enum TransactionRoute{
//    case main
//    case detail
//}

enum WalletRoute: Hashable {
    case me, utxos, transactions, contacts

    case send(selected: Set<String>)

    static var allCases: [WalletRoute] {
        [.me, .utxos, .transactions, .send(selected: .init()), .contacts]
    }

    var icon: String {
        switch self {
        case .me: "person"
        case .utxos: "bitcoinsign"
        case .transactions: "dollarsign"
        case .send: "paperplane"
        case .contacts: "person.2"
        }
    }

    var title: String {
        switch self {
        case .me: "Me"
        case .utxos: "Utxos"
        case .transactions: "Transactions"
        case .send: "Send"
        case .contacts: "Contacts"
        }
    }
}

enum ToolRoute: String, Hashable, CaseIterable {
    case broadcast, sign
    // speedUp, cancelTx, monitor

    static var allCases: [ToolRoute] {
        [.broadcast, .sign]
    }

    var title: String {
        switch self {
        case .broadcast: "Broadcast"
        case .sign: "Sign"
        }
    }

    var icon: String {
        switch self {
        case .broadcast: "dot.radiowaves.left.and.right"
        case .sign: "square.and.pencil"
        }
    }
}

enum NavigationType: Hashable {
    case push(Route)
    case unwind(Route)
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
