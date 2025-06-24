//
//  Esplora+Extensions.swift
//  Decentralized
//
//  Created by Nekilc on 2024/8/31.
//

import DecentralizedFFI

extension DecentralizedFFI.Tx: @retroactive Identifiable {
    public var id: Txid {
        self.txid
    }

    public var feeRate: UInt64 {
        self.fee / (self.weight / 4)
    }
}

extension PrevOut {
    func address(network: Network) -> Address {
        return try! Address.fromScript(script: self.scriptpubkey, network: network)
    }
}

extension DecentralizedFFI.Vout {
    func address(network: Network) -> Address {
        return try! Address.fromScript(script: self.scriptpubkey, network: network)
    }
}
