//
//  Transaction+Extensions.swift
//  BDKSwiftExampleWallet
//
//  Created by Matthew Ramsden on 9/21/23.
//

import BitcoinDevKit
import Foundation

extension CanonicalTx: @retroactive Identifiable {
    public var id: String {
        self.transaction.transactionID
    }
}

extension Transaction: @retroactive Identifiable {
    public var id: String { self.computeTxid() }
}

extension Transaction: @retroactive Equatable, @retroactive Hashable {
    public static func == (lhs: BitcoinDevKit.Transaction, rhs: BitcoinDevKit.Transaction) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

extension String {
    func hexStringToByteArray() -> [UInt8] {
        var startIndex = self.startIndex
        var byteArray: [UInt8] = []

        while startIndex < self.endIndex {
            let endIndex =
                self.index(startIndex, offsetBy: 2, limitedBy: self.endIndex) ?? self.endIndex
            let byteString = self[startIndex ..< endIndex]
            if let byte = UInt8(byteString, radix: 16) {
                byteArray.append(byte)
            } else {
                return []
            }
            startIndex = endIndex
        }

        return byteArray
    }
}

extension BitcoinDevKit.Transaction {
    var transactionID: String {
        return self.computeTxid()
    }

    var vsize: UInt64 {
        self.vsize()
    }
}

extension CanonicalTx {
    var timestamp: UInt64 {
        switch self.chainPosition {
        case .confirmed(let ts): ts.confirmationTime
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


