//
//  LocalOut+Extensions.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/27.
//

import BitcoinDevKit
import Foundation

extension LocalOutput: @retroactive Identifiable {
    public var id: String {
        "\(self.outpoint.txid):\(self.outpoint.vout)"
    }
}

extension LocalOutput: @retroactive Equatable {
    public static func == (lhs: LocalOutput, rhs: LocalOutput) -> Bool {
        return lhs.id == rhs.id
    }
}

extension LocalOutput: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

public extension LocalOutput {
    var diplayBTCValue: String {
        Amount.fromSat(fromSat: self.txout.value).displayBtc
    }
}
