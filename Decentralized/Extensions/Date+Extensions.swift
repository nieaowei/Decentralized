//
//  Date+Extensions.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/27.
//

import Foundation

extension Date {
    func commonFormat() -> String {
        self.ISO8601Format(.iso8601(timeZone: .gmt, dateTimeSeparator: .space))
    }

    func dateFormat() -> String {
        self.ISO8601Format(.iso8601(timeZone: .gmt, dateTimeSeparator: .space))
    }

    func monDayFormat() -> String {
        let fs = DateFormatter()
        fs.dateFormat = "MM-dd"
        return fs.string(from: self)
    }
}
