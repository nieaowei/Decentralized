//
//  Contact.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/31.
//

import DecentralizedFFI
import Foundation
import SwiftData

@Model
class Contact: Identifiable, Hashable {
    @Attribute(.unique)
    var id: UUID

    @Attribute(.unique)
    var addr: String

    var label: String

    var network: String = Network.bitcoin.rawValue

    var minimalNonDust: UInt64 = 256

    var lastUsedTs: UInt64 = Date.nowTs()

    var deletable: Bool = true

    init(addr: String, label: String = "", minimalNonDust: UInt64 = 256, network: Network = .bitcoin, deletable: Bool = true) {
        self.id = UUID()
        self.addr = addr
        self.label = label
        self.network = network.rawValue
        self.lastUsedTs = Date.nowTs()
        self.minimalNonDust = minimalNonDust
        self.deletable = deletable
    }

    init(addr: Address, label: String = "", network: Network = .bitcoin, deletable: Bool = true) {
        self.id = UUID()
        self.addr = addr.description
        self.label = label
        self.network = network.rawValue
        self.lastUsedTs = Date.nowTs()
        self.minimalNonDust = addr.minimalNonDust().toSat()
        self.deletable = deletable
    }

//    static func fetch
}

extension Contact {
    static func predicate(search: String, network: Network? = nil) -> Predicate<Contact> {
        let hasTypeRaw = network != nil
        let typeRaw = hasTypeRaw ? network!.rawValue : Network.bitcoin.rawValue

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
