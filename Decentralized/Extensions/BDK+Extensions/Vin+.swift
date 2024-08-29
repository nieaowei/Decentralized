//
//  Vin+.swift
//  Decentralized
//
//  Created by Nekilc on 2024/7/18.
//

import BitcoinDevKit

extension TxIn: @retroactive Identifiable {
    public var id: String {
        "\(self.previousOutput.txid):\(self.previousOutput.vout)"
    }
}

extension TxOut: @retroactive Identifiable {
    public var id: String {
        "\(self.scriptPubkey):\(self.value)"
    }
}
