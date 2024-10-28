//
//  Network+Extensions.swift
//  BDKSwiftExampleWallet
//
//  Created by Matthew Ramsden on 9/4/23.
//

import DecentralizedFFI
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

    var accentColor: Color {
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

    func toBitcoinNetwork() -> Network {
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

    func toCustomNetwork() -> Network {
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
