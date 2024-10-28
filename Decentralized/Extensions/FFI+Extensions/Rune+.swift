//
//  Rune+.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/28.
//

import DecentralizedFFI
import Foundation

extension Edict: @retroactive CustomStringConvertible {
    public var description: String {
        return "Rune(\(self.id)):\(self.amount):\(self.output)"
    }
}

extension RuneId {
    static func fromString(string: String) -> Result<RuneId, ParseRuneIdError> {
        Result {
            try RuneId.fromString(s: string)
        }
    }
}

func buildRuneSnipePsbt(
    cardinalUtxos: [LocalOutput],
    snipeUtxoPairs: [SnipeRuneUtxoPair],
    payAddr: Address,
    ordiAddr: Address,
    snipeMinFee: Amount,
    snipeRate: FeeRate,
    splitRate: FeeRate,
    runeRecvAddr: Address?
) -> Result<SnipePsbtPair, SnipeError> {
    Result {
        try buildRuneSnipePsbt(cardinalUtxos: cardinalUtxos, snipeUtxoPairs: snipeUtxoPairs, payAddr: payAddr, ordiAddr: ordiAddr, snipeMinFee: snipeMinFee, snipeRate: snipeRate, splitRate: splitRate, runeRecvAddr: runeRecvAddr)
    }
}

func buildInscriptionSnipePsbt(
    cardinalUtxos: [LocalOutput],
    dummyUtxos: [LocalOutput],
    snipeUtxoPairs: [SnipeInscriptionPair],
    payAddr: Address,
    ordiAddr: Address,
    snipeMinFee: Amount,
    snipeRate: FeeRate,
    splitRate: FeeRate,
    inscriptionRecvAddr: Address?
) -> Result<SnipePsbtPair, SnipeError> {
    Result {
        try buildInscriptionSnipePsbt(cardinalUtxos: cardinalUtxos, dummyUtxos: dummyUtxos, snipeUtxoPairs: snipeUtxoPairs, payAddr: payAddr, ordiAddr: ordiAddr, snipeMinFee: snipeMinFee, snipeRate: snipeRate, splitRate: splitRate, inscriptionRecvAddr: inscriptionRecvAddr)
    }
}
