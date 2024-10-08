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

// enum TransactionRoute{
//    case main
//    case detail
// }

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
    case broadcast, sign, ordinal
    // speedUp, cancelTx, monitor

    static var allCases: [ToolRoute] {
        [.broadcast, .sign, .ordinal]
    }

    var title: String {
        switch self {
        case .broadcast: "Broadcast"
        case .sign: "Sign"
        case .ordinal: "Ordinal"
        }
    }

    var icon: String {
        switch self {
        case .broadcast: "dot.radiowaves.left.and.right"
        case .sign: "square.and.pencil"
        case .ordinal: "pencil"
        }
    }
}

//
enum SendRoute: Hashable {
    case main(selected: Set<String>)
    case detail(tx: WalletTransaction)

//    static var allCases: [SendRoute] {
//        [.SendRoute, .detail(tx: <#T##WalletTransaction#>)]
//    }
}

enum NavigationType: Hashable {
    case push(Route)
    case goto(Route)
    case unwind(Route)
}
