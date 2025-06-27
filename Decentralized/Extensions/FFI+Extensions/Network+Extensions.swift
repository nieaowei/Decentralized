//
//  Network+Extensions.swift
//  BDKSwiftExampleWallet
//
//  Created by Matthew Ramsden on 9/4/23.
//

import DecentralizedFFI
import Foundation
import SwiftUI

//
//// typealias Networks = CustomNetwork
extension Network: @retroactive Identifiable, @retroactive CaseIterable, @retroactive RawRepresentable, Codable {
    public typealias RawValue = String

    public init?(rawValue: String) {
        switch rawValue {
        case "bitcoin": self = .bitcoin
        case "testnet": self = .testnet
        case "testnet4": self = .testnet4
        case "signet": self = .signet
        case "regtest": self = .regtest
        default: return nil
        }
    }

    public var rawValue: String {
        switch self {
        case .bitcoin:
            "bitcoin"
        case .testnet:
            "testnet"
        case .testnet4:
            "testnet4"
        case .signet:
            "signet"
        case .regtest:
            "regtest"
        }
    }

    public static var allCases: [Network] = [
        .bitcoin,
        .testnet,
        .testnet4,
        .signet,
        .regtest
    ]

    public var id: String {
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
}
//
//enum Networks: String, Codable, CaseIterable, Identifiable {
//    case bitcoin
//    case testnet
//    case testnet4
//    case signet
//    case regtest
//
//    var id: String {
//        self.rawValue
//    }
//
//    var accentColor: Color {
//        switch self {
//        case .bitcoin:
//            .orange
//        case .testnet:
//            .green
//        case .testnet4:
//            .green
//        case .signet:
//            .purple
//        case .regtest:
//            .yellow
//        }
//    }
//
//    func toBitcoinNetwork() -> Network {
//        switch self {
//        case .bitcoin:
//            .bitcoin
//        case .testnet:
//            .testnet
//        case .testnet4:
//            .testnet4
//        case .signet:
//            .signet
//        case .regtest:
//            .regtest
//        }
//    }
//
//    func toCustomNetwork() -> Network {
//        switch self {
//        case .bitcoin:
//            .bitcoin
//        case .testnet:
//            .testnet
//        case .testnet4:
//            .testnet4
//        case .signet:
//            .signet
//        case .regtest:
//            .regtest
//        }
//    }
//}
