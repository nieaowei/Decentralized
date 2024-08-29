//
//  BackupInfo.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/24.
//

import Foundation

struct BackupInfo: Codable, Equatable {
    var mnemonic: String
    var payDescriptor: String
    var payChangeDescriptor: String
    var payAddress: String

    var ordiDescriptor: String
    var ordiChangeDescriptor: String
    var ordiAddress: String

    var mode: WalletMode

    init(mnemonic: String, payDescriptor: String, payChangeDescriptor: String, payAddress: String, ordiDescriptor: String, ordiChangeDescriptor: String, ordiAddress: String, mode: WalletMode) {
        self.mnemonic = mnemonic
        self.payDescriptor = payDescriptor
        self.payChangeDescriptor = payChangeDescriptor
        self.payAddress = payAddress
        self.ordiDescriptor = ordiDescriptor
        self.ordiChangeDescriptor = ordiChangeDescriptor
        self.ordiAddress = ordiAddress
        self.mode = mode
    }

    static func == (lhs: BackupInfo, rhs: BackupInfo) -> Bool {
        return lhs.mnemonic == rhs.mnemonic && lhs.payDescriptor == rhs.payDescriptor
            && lhs.ordiDescriptor == rhs.ordiDescriptor && lhs.payAddress == rhs.payAddress && lhs.ordiAddress == rhs.ordiAddress && lhs.payChangeDescriptor == rhs.payChangeDescriptor && lhs.ordiChangeDescriptor == rhs.ordiChangeDescriptor
    }
}

enum CurrencyCode: String {
    case USD
    case EUR
    case GBP
    case CAD
    case CHF
    case AUD
    case JPY
}
