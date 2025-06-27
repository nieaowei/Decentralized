//
//  Contact.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/31.
//

import Foundation
import SwiftData

@Model
class Contact: Identifiable, Hashable {
    @Attribute(.unique)
    var id: UUID

    @Attribute(.unique)
    var addr: String

    var label: String

    var network: String

    var minimalNonDust: UInt64

    var lastUsedTs: UInt64

    init(addr: String, label: String = "", minimalNonDust: UInt64 = 256, network: Networks = .bitcoin,) {
        self.id = UUID()
        self.addr = addr
        self.label = label
        self.network = network.rawValue
        self.lastUsedTs = Date.nowTs()
        self.minimalNonDust = minimalNonDust
    }

//    static func fetch
}

extension Contact {
    static func predicate(search: String, network: Networks? = nil) -> Predicate<Contact> {
        let hasTypeRaw = network != nil
        let typeRaw = hasTypeRaw ? network!.rawValue : Networks.bitcoin.rawValue

        return #Predicate { ordi in
            (search.isEmpty || ordi.label.localizedStandardContains(search) || ordi.addr.localizedStandardContains(search)) && (!hasTypeRaw || ordi.network == typeRaw)
        }
    }

    static func fetchOneById(ctx: ModelContext, id: UUID) -> Result<Contact?, Error> {
        return ctx.fetchOne(predicate: #Predicate { $0.id == id })
    }

    static func fetchByIds(ctx: ModelContext, ids: [UUID]) -> Result<[Contact], Error> {
        ctx.fetchMany(predicate: #Predicate { ids.contains($0.id) })
    }
}
