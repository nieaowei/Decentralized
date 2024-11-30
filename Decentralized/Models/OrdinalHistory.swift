//
//  Ordinal.swift
//  Decentralized
//
//  Created by Nekilc on 2024/11/29.
//

import SwiftData
import Foundation

@Model
class OrdinalHistory {
    var commitTxId: String
    var revealTxId: String
    var commitPsbtHex: String
    var revealTxHex: String
    var revealPk: String
    var createTs: UInt64
    
    init(commitTxId: String, revealTxId: String, commitPsbtHex: String, revealTxHex: String, revealPk: String) {
        self.commitTxId = commitTxId
        self.revealTxId = revealTxId
        self.commitPsbtHex = commitPsbtHex
        self.revealTxHex = revealTxHex
        self.revealPk = revealPk
        self.createTs = UInt64(Date().timeIntervalSince1970)
    }
   
}
