//
//  BDKError+Extensions.swift
//  BDKSwiftExampleWallet
//
//  Created by Matthew Ramsden on 9/5/23.
//

import DecentralizedFFI
import Foundation

//extension EsploraError: Sendable {}

extension CalculateFeeError {
    var description: String {
        switch self {
        case .MissingTxOut(let outPoints):
            return outPoints.description
        case .NegativeFee(let fee):
            return fee.description
        }
    }
}

extension CannotConnectError {
    var description: String {
        switch self {
        case .Include(let height):
            return "Include height \(height)"
        }
    }
}

extension DescriptorError {
    var description: String {
        switch self {
        case .InvalidHdKeyPath:
            return "InvalidHdKeyPath"
        case .InvalidDescriptorChecksum:
            return "InvalidDescriptorChecksum"
        case .HardenedDerivationXpub:
            return "HardenedDerivationXpub"
        case .MultiPath:
            return "MultiPath"
        case .Key(let errorMessage):
            return errorMessage
        case .Policy(let errorMessage):
            return errorMessage
        case .InvalidDescriptorCharacter(let char):
            return char
        case .Bip32(let errorMessage):
            return errorMessage
        case .Base58(let errorMessage):
            return errorMessage
        case .Pk(let errorMessage):
            return errorMessage
        case .Miniscript(let errorMessage):
            return errorMessage
        case .Hex(let errorMessage):
            return errorMessage
        case .ExternalAndInternalAreTheSame:
            return "ExternalAndInternalAreTheSame"
        }
    }
}

extension EsploraError {
    var description: String {
        switch self {
        case .HeaderHeightNotFound(let height):
            return height.description
        case .TransactionNotFound:
            return "Transaction not found."
        case .HeaderHashNotFound:
            return "Header hash not found."
        case .Minreq(let errorMessage):
            return errorMessage
        case .HttpResponse(let status, let errorMessage):
            return "\(status): \(errorMessage)"
        case .Parsing(let errorMessage):
            return errorMessage
        case .StatusCode(let errorMessage):
            return errorMessage
        case .BitcoinEncoding(let errorMessage):
            return errorMessage
        case .HexToArray(let errorMessage):
            return errorMessage
        case .HexToBytes(let errorMessage):
            return errorMessage
        case .InvalidHttpHeaderName(let name):
            return name
        case .InvalidHttpHeaderValue(let value):
            return value
        case .RequestAlreadyConsumed:
            return "Request Already Consumed."
        case .InvalidResponse:
            return "Invalid Response"
        }
    }
}

extension PersistenceError {
    var description: String {
        switch self {
        case .Reason(let errorMessage):
            return "Write \(errorMessage)"
        }
    }
}

extension SignerError {
    var description: String {
        switch self {
        case .MissingKey:
            return "MissingKey"
        case .InvalidKey:
            return "InvalidKey"
        case .UserCanceled:
            return "UserCanceled"
        case .InputIndexOutOfRange:
            return "InputIndexOutOfRange"
        case .MissingNonWitnessUtxo:
            return "MissingNonWitnessUtxo"
        case .InvalidNonWitnessUtxo:
            return "InvalidNonWitnessUtxo"
        case .MissingWitnessUtxo:
            return "MissingWitnessUtxo"
        case .MissingWitnessScript:
            return "MissingWitnessScript"
        case .MissingHdKeypath:
            return "MissingHdKeypath"
        case .NonStandardSighash:
            return "NonStandardSighash"
        case .InvalidSighash:
            return "InvalidSighash"
        case .SighashP2wpkh(let errorMessage):
            return errorMessage
        case .SighashTaproot(let errorMessage):
            return errorMessage
        case .MiniscriptPsbt(let errorMessage):
            return errorMessage
        case .External(let errorMessage):
            return errorMessage
        case .TxInputsIndexError(errorMessage: let errorMessage):
            return errorMessage
        case .Psbt(errorMessage: let errorMessage):
            return errorMessage
        }
    }
}

// extension WalletCreationError {
//    var description: String {
//        switch self {
//        case .Descriptor:
//            return "descriptor"
//        case .LoadedGenesisDoesNotMatch:
//            return "loaded genesis does not match"
//        case .LoadedNetworkDoesNotMatch(let expected, let got):
//            return "got: \(String(describing: got)), expected \(expected)"
//
//        case .LoadedDescriptorDoesNotMatch(let got, let keychain):
//            return "got: \(String(describing: got)), keychain \(keychain)"
//        }
//    }
// }
