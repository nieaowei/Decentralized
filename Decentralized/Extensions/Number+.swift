//
//  Number+.swift
//  Decentralized
//
//  Created by Nekilc on 2024/10/17.
//

import DecentralizedFFI
import Foundation

extension Double {
    var displayBtc: String {
        if self <= 0 {
            String(format: "%.8f BTC", arguments: [self])
        } else {
            String(format: "+%.8f BTC", arguments: [self])
        }
    }

    var displaySatsUnit: String {
        if self < 0.01 {
            String(format: "%.8f sats/unit", arguments: [self])
        } else {
            String(format: "%.2f sats/unit", arguments: [self])
        }
    }
}

extension UInt32 {
    private static let numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal

        return numberFormatter
    }()

    var delimiter: String {
        return UInt32.numberFormatter.string(from: NSNumber(value: self)) ?? ""
    }
}

extension UInt64 {
    private static let numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal

        return numberFormatter
    }()

    var delimiter: String {
        return UInt64.numberFormatter.string(from: NSNumber(value: self)) ?? ""
    }
}

extension UInt64 {
    var amount: Amount {
        Amount.fromSat(satoshi: self)
    }
    
    func toBtc() -> Double{
        self.amount.toBtc()
    }

    func formattedSatoshis() -> String {
        if self == 0 {
            return "0.00 000 000"
        } else {
            let balanceString = String(format: "%010d", self)

            let zero = balanceString.prefix(2)
            let first = balanceString.dropFirst(2).prefix(2)
            let second = balanceString.dropFirst(4).prefix(3)
            let third = balanceString.dropFirst(7).prefix(3)

            var formattedZero = zero

            if zero == "00" {
                formattedZero = zero.dropFirst()
            } else if zero.hasPrefix("0") {
                formattedZero = zero.suffix(1)
            }

            let formattedBalance = "\(formattedZero).\(first) \(second) \(third)"

            return formattedBalance
        }
    }
}

extension Int {
    func newDateAgo() -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(self))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let relativeDate = formatter.localizedString(for: date, relativeTo: Date.now)

        return relativeDate
    }
}

extension UInt64 {
    func toDate() -> Date {
        return Date(timeIntervalSince1970: TimeInterval(self))
    }
}
