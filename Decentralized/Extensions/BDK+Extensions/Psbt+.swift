//
//  Psbt+.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/15.
//

import BitcoinDevKit

extension Psbt: @retroactive Equatable, @retroactive Hashable {
    public static func == (lhs: Psbt ,rhs: Psbt) -> Bool {
        lhs.serializeHex() == rhs.serializeHex()
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.serializeHex())
    }
}
