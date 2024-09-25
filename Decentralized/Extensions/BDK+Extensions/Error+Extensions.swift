//
//  Error+Extensions.swift
//  Decentralized
//
//  Created by Nekilc on 2024/8/30.
//

import BitcoinDevKit
import Foundation

extension CreateTxError: LocalizedError {
    public var errorDescription: String? {
        return switch self {
        case .Descriptor(let errorMessage):
            "Descriptor(\(errorMessage)"
        case .Policy(let errorMessage):
            "Policy(\(errorMessage)"
        case .SpendingPolicyRequired(let kind):
            "SpendingPolicyRequired(\(kind.debugDescription)"
        case .Version0:
            "Version0"
        case .Version1Csv:
            "Version1Csv"
        case .LockTime(let requested, let required):
            "LockTime"
        case .RbfSequence:
            "RbfSequence"
        case .RbfSequenceCsv(let rbf, let csv):
            "RbfSequenceCsv"
        case .FeeTooLow(let required):
            "FeeTooLow"
        case .FeeRateTooLow(let required):
            "FeeRateTooLow"
        case .NoUtxosSelected:
            "FeeRateTooLow"
        case .OutputBelowDustLimit(let index):
            "OutputBelowDustLimit"
        case .ChangePolicyDescriptor:
            "ChangePolicyDescriptor"
        case .CoinSelection(let errorMessage):
            "CoinSelection"
        case .InsufficientFunds(let needed, let available):
            "FeeRateTooLow"
        case .NoRecipients:
            "NoRecipients"
        case .Psbt(let errorMessage):
            "Psbt"
        case .MissingKeyOrigin(let key):
            "MissingKeyOrigin"
        case .UnknownUtxo(let outpoint):
            "UnknownUtxo"
        case .MissingNonWitnessUtxo(let outpoint):
            "MissingNonWitnessUtxo"
        case .MiniscriptPsbt(let errorMessage):
            "MiniscriptPsbt"
        }
        
    }
}
