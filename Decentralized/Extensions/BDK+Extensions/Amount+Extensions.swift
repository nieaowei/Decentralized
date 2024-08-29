//
//  Amount+Extensions.swift
//  BDKSwiftExampleWallet
//
//  Created by Matthew Ramsden on 5/22/24.
//

import BitcoinDevKit
import Foundation

extension Amount: @retroactive Equatable {
    public static func == (lhs: Amount, rhs: Amount) -> Bool {
        return lhs.toSat() == rhs.toSat()
    }
}

extension Amount {
    var displayBtc: String {
        String(format: "%.8f BTC", arguments: [toBtc()])
    }
}

extension Amount {
    static func + (left: Amount, right: Amount) -> Amount {
        return Amount.fromSat(fromSat: left.toSat() + right.toSat())
    }
}


extension Double{
    var displayBtc: String {
        String(format: "%.8f BTC", arguments: [self])
    }
}
