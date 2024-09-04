//
//  Network+Extensions.swift
//  BDKSwiftExampleWallet
//
//  Created by Matthew Ramsden on 9/4/23.
//

import BitcoinDevKit
import Foundation

enum Networks: String {
    case bitcoin
    case testnet
    case signet
    case regtest

    func toBdkNetwork() -> Network {
        switch self {
        case .bitcoin:
            Network.bitcoin
        case .testnet:
            .testnet
        case .signet:
            .signet
        case .regtest:
            .regtest
        }
    }
}

extension Network {
    var description: String {
        switch self {
        case .bitcoin: return "bitcoin"
        case .testnet: return "testnet"
        case .signet: return "signet"
        case .regtest: return "regtest"
        }
    }

    init?(stringValue: String) {
        switch stringValue {
        case "bitcoin": self = .bitcoin
        case "testnet": self = .testnet
        case "signet": self = .signet
        case "regtest": self = .regtest
        default: return nil
        }
    }
}
