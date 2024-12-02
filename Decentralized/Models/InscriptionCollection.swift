//
//  InscriptionCollection.swift
//  Decentralized
//
//  Created by Nekilc on 2024/11/30.
//

import Foundation
import SwiftData

@Model
class InscriptionCollection {
    var name: String
    var startNumber: UInt64
    var endNumber: UInt64
    var createTs: UInt64

    init(name: String, startNumber: UInt64, endNumber: UInt64) {
        self.name = name
        self.startNumber = startNumber
        self.endNumber = endNumber
        self.createTs = UInt64(Date().timeIntervalSince1970)
    }

    static func fetchNameByNumber(ctx: ModelContext, number: UInt64) -> Result<String?, Error> {
        ctx.fetchOne(predicate: #Predicate<InscriptionCollection> { number >= $0.startNumber && number <= $0.endNumber }, includePendingChanges: true)
            .map { coll in
                coll?.name
            }
    }
}
