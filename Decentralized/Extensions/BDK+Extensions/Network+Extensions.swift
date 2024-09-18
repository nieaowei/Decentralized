//
//  Network+Extensions.swift
//  BDKSwiftExampleWallet
//
//  Created by Matthew Ramsden on 9/4/23.
//

import BitcoinDevKit
import Foundation
import SwiftUI

// typealias Networks = CustomNetwork

enum Networks: String, Codable, CaseIterable, Identifiable {
    case bitcoin
    case testnet
    case testnet4
    case signet
    case regtest

    var id: String {
        self.rawValue
    }
    
    var accentColor:Color{
        switch self {
        case .bitcoin:
                .orange
        case .testnet:
                .green
        case .testnet4:
                .green
        case .signet:
                .purple
        case .regtest:
                .yellow
        }
    }

    func toBdkNetwork() -> Network {
        switch self {
        case .bitcoin:
            .bitcoin
        case .testnet:
            .testnet
        case .testnet4:
            .testnet
        case .signet:
            .signet
        case .regtest:
            .regtest
        }
    }

    func toCustomNetwork() -> CustomNetwork {
        switch self {
        case .bitcoin:
            .bitcoin
        case .testnet:
            .testnet
        case .testnet4:
            .testnet4
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
