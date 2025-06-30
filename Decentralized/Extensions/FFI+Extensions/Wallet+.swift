//
//  Wallet+.swift
//  Decentralized
//
//  Created by Nekilc on 2024/10/17.
//

import DecentralizedFFI
import CoreTransferable
import Foundation

extension Balance: @retroactive Equatable {
    public static func == (lhs: Balance, rhs: Balance) -> Bool {
        return lhs.immature == rhs.immature &&
            lhs.trustedPending == rhs.trustedPending &&
            lhs.untrustedPending == rhs.untrustedPending &&
            lhs.confirmed == rhs.confirmed &&
            lhs.trustedSpendable == rhs.trustedSpendable &&
            lhs.total == rhs.total
    }

    public static let Zero: Balance = .init(immature: .Zero, trustedPending: .Zero, untrustedPending: .Zero, confirmed: .Zero, trustedSpendable: .Zero, total: .Zero)
}

extension CanonicalTx: @retroactive Identifiable {
    public var id: Txid {
        self.transaction.id
    }

    var timestamp: UInt64 {
        switch self.chainPosition {
        case .confirmed(let confirmationBlockTime, _): confirmationBlockTime.confirmationTime
        case .unconfirmed: UInt64(Date().timeIntervalSince1970)
        }
    }

    var date: Date {
        return Calendar.current.startOfDay(for: self.timestamp.toDate())
    }

    var isComfirmed: Bool {
        switch self.chainPosition {
        case .confirmed: true
        case .unconfirmed: false
        }
    }
}

extension LocalOutput: @retroactive Identifiable, @retroactive Equatable, @retroactive Hashable {
    public var id: String {
        "\(self.outpoint.txid):\(self.outpoint.vout)"
    }

    public static func == (lhs: LocalOutput, rhs: LocalOutput) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

import UniformTypeIdentifiers


//extension LocalOutput: @retroactive Transferable {
//    static var draggableType = UTType(exportedAs: "itsuki.enjoy.TableDemo.pokemon")
//
//    public static var transferRepresentation: some TransferRepresentation {
//        CodableRepresentation(contentType: .text)
//    }
//}
//
//extension LocalOutput: Codable {
//    
//}
