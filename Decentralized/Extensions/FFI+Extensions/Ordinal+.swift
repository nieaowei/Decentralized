//
//  Ordinal+.swift
//  Decentralized
//
//  Created by Nekilc on 2024/11/29.
//

import DecentralizedFFI

func mintOrd(network: Network, utxos: [LocalOutput], file: NamedFile, payAddress: String, toAddr: String, feeRate: UInt64, postage: UInt64?) async -> Result<Output, MintError> {
    await Result {
        try await mint(network: network, utxos: utxos, file: file, payAddress: payAddress, toAddr: toAddr, feeRate: feeRate, postage: postage)
    }
}
