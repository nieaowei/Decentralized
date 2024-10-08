//
//  Vin+.swift
//  Decentralized
//
//  Created by Nekilc on 2024/7/18.
//

import BitcoinDevKit
import Foundation

extension TxIn: @retroactive Identifiable {
    public var id: String {
        "\(self.previousOutput.txid):\(self.previousOutput.vout)"
    }
}

extension TxOut {
    func address(network: Network) throws -> String {
        return try Address.fromScript(script: self.scriptPubkey, network: network).description
    }

    var amount: Amount {
        return Amount.fromSat(fromSat: self.value)
    }
}

struct TxOutRow: Identifiable {
    let id: UUID = .init()
    let inner: TxOut

    func address(network: Network) throws -> String {
        return try Address.fromScript(script: self.inner.scriptPubkey, network: network).description
    }

    var amount: Amount {
        return Amount.fromSat(fromSat: self.inner.value)
    }
}
