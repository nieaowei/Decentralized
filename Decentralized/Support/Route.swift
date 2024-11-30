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
    case me, utxos, contacts

    case transactions(TransactionRoutes)

    case send(selected: Set<String>)

    case sign

    static var allCases: [WalletRoute] {
        [.me, .utxos, .transactions(.list), .send(selected: .init()), sign, .contacts]
    }

    var icon: String {
        switch self {
        case .me: "person"
        case .utxos: "bitcoinsign"
        case .transactions: "dollarsign"
        case .send: "paperplane"
        case .sign: "square.and.pencil"
        case .contacts: "person.2"
        }
    }

    var title: String {
        switch self {
        case .me: "Me"
        case .utxos: "Utxos"
        case .transactions: "Transactions"
        case .send: "Send"
        case .sign: "Sign"
        case .contacts: "Contacts"
        }
    }
}

enum TransactionRoutes: Hashable {
    case list
    case detail(tx: WalletTransaction)

    var title: String {
        switch self {
        case .list: "Transactions"
        case .detail: "Transaction Detail"
        }
    }

//    var icon: String {
//        switch self {
//        case .list: "dot.radiowaves.left.and.right"
//        case .detail: "square.and.pencil"
//        }
//    }
}

enum ToolRoute: String, Hashable, CaseIterable {
    case broadcast, ordinal, mempoolMonitor
    // speedUp, cancelTx, monitor

    static var allCases: [ToolRoute] {
        [.mempoolMonitor, .broadcast, ordinal]
    }

    var title: String {
        switch self {
        case .broadcast: "Broadcast"
        case .ordinal: "Ordinal"
        case .mempoolMonitor: "Mempool"
        }
    }

    var icon: String {
        switch self {
        case .broadcast: "dot.radiowaves.left.and.right"
        case .ordinal: "smallcircle.circle"
        case .mempoolMonitor: "leaf"
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
