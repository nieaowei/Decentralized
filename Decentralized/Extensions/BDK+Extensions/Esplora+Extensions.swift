//
//  Esplora+Extensions.swift
//  Decentralized
//
//  Created by Nekilc on 2024/8/31.
//

import BitcoinDevKit

extension BitcoinDevKit.Tx: @retroactive Identifiable {
    public var id: String {
        self.txid
    }
}

extension BitcoinDevKit.PrevOut {
    func address(network:Network) -> Address {
        return try! Address.fromScript(script: self.scriptpubkey, network: network)
    }
}

extension BitcoinDevKit.Vout{
    func address(network:Network) -> Address {
        return try! Address.fromScript(script: self.scriptpubkey, network: network)
    }
}
