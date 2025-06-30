//
//  Navigation.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/4.
//

import Foundation
import DecentralizedFFI
import SwiftUI

struct NavigateAction {
    typealias Action = (NavigationType) -> ()
    let action: Action
    func callAsFunction(_ navigationType: NavigationType) {
        action(navigationType)
    }
}

enum Route: Hashable, Sendable {
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

enum WalletRoute: Hashable, Sendable {
    case me, utxos, contacts

    case transactions(TransactionRoutes)

    case send(selected: Set<String>)

    case hexTxSign

    case txSign(unsignedPsbts: [TxSignScreen.UnsignedPsbt])

    static var allCases: [WalletRoute] {
        [.me, .utxos, .transactions(.list), .send(selected: .init()), hexTxSign, .contacts]
    }

    var icon: String {
        switch self {
        case .me: "person"
        case .utxos: "bitcoinsign"
        case .transactions: "dollarsign"
        case .send: "paperplane"
        case .hexTxSign: "square.and.pencil"
        case .contacts: "person.2"
        case .txSign:
            ""
        }
    }

    var title: String {
        switch self {
        case .me: "Me"
        case .utxos: "Utxos"
        case .transactions: "Transactions"
        case .send: "Send"
        case .hexTxSign: "Hex Sign"
        case .contacts: "Contacts"
        case .txSign:
            "Transaction Sign"
        }
    }
}

enum TransactionRoutes: Hashable, Sendable {
    case list
    case detail(tx: TxDetails)

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

enum ToolRoute: String, Hashable, CaseIterable, Sendable {
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
enum SendRoute: Hashable, Sendable {
    case main(selected: Set<String>)
    case detail(tx: WalletTransaction)

//    static var allCases: [SendRoute] {
//        [.SendRoute, .detail(tx: <#T##WalletTransaction#>)]
//    }
}

enum NavigationType: Hashable, Sendable {
    case push(Route)
    case goto(Route)
    case unwind(Route)
}
