//
//  Ordinal.swift
//  Decentralized
//
//  Created by Nekilc on 2024/10/11.
//

import DecentralizedFFI
import Foundation
import SwiftData

enum OrdinalType: Int, Codable, CaseIterable, Identifiable {
    case rune
    case inscription
    case fund
    
    var id: Int {
        rawValue
    }
}

@Model
class MempoolOrdinal: Identifiable {
    @Attribute(.unique) var id: String
    
    @Attribute(.unique) var outpoint: String
    
    var txid: String
    var vout: UInt32
    
    var typeRaw: Int
    
    var type: OrdinalType {
        get { OrdinalType(rawValue: typeRaw) ?? .fund }
        set { typeRaw = newValue.rawValue }
    }
    
    var ordinalId: String // runeid  or  inscription id
    
    var name: String // rune name or
    var value: UInt64
    
    var number: UInt64
//    var fee: UInt64
//
    var feeRate: Double
    
    var txinHex: String
    var witnessHex: String
    var txoutHex: String
    
    var amount: String
    var div: String
    
    var isUsed: Bool = false
    
    var createTs: UInt64
    
    init(type: OrdinalType, txin: TxIn, txout: TxOut, feeRate: Double, ordinalId: String, name: String, number: UInt64 = 0, amount: String = "1", div: String = "0") {
        self.id = txin.id
        self.outpoint = txin.id
        self.ordinalId = ordinalId
        self.name = name
        self.number = number
        self.value = txout.value.toSat()
        self.txinHex = txin.serializeHex
        self.witnessHex = txin.witnessHex
        self.txoutHex = txout.serializeHex
        self.createTs = UInt64(Date().timeIntervalSince1970)
        self.amount = amount
        self.div = div
        self.txid = txin.previousOutput.txid.description
        self.vout = txin.previousOutput.vout
        self.typeRaw = type.rawValue
        self.feeRate = feeRate
    }
    
    static func clearConfirmed(ctx: ModelContext, blockMinFeeRate: Double) throws {
        try ctx.delete(model: MempoolOrdinal.self, where: #Predicate<MempoolOrdinal> { ordi in
            ordi.feeRate >= blockMinFeeRate
        })
    }
}

extension MempoolOrdinal: Hashable {
    var amountWithDiv: Double {
        let div = Int(div) ?? 0
        var amount = amount
        if div > 0 {
            if amount.count < div {
                amount = amount.padding(toLength: div, withPad: "0", startingAt: 0)
            }
            let insertIndex = amount.index(amount.endIndex, offsetBy: -div)

            var modifiedString = amount
            modifiedString.insert(".", at: insertIndex)
                
            return Double(modifiedString)!
        } else {
            return Double(amount)!
        }
    }
    
    var avgValue: Double {
        Double(value) / amountWithDiv
    }
    
    var displayName: String {
        if !name.isEmpty {
            name + (!ordinalId.isEmpty ? "(\(ordinalId))" : "")
        } else {
            ordinalId
        }
    }
    
    var displayAmount: String {
        amountWithDiv.description
    }
    
    var displayDate: String {
        createTs.toDate().commonFormat()
    }
}

extension MempoolOrdinal {
    static func predicate(search: String, type: OrdinalType? = nil, isUsed: Bool? = nil) -> Predicate<MempoolOrdinal> {
        let hasTypeRaw = type != nil
        let typeRaw = hasTypeRaw ? type!.rawValue : OrdinalType.rune.rawValue
        
        let hasIsUsedRaw = isUsed != nil
        let isUsedRaw = hasIsUsedRaw ? isUsed! : false
        
        return #Predicate { ordi in
            (search.isEmpty || ordi.name.localizedStandardContains(search)) && (!hasTypeRaw || ordi.typeRaw == typeRaw) && (!hasIsUsedRaw || ordi.isUsed == isUsedRaw)
        }
    }
    
    static func fetchOneByOp(ctx: ModelContext, outpoint: String) -> Result<MempoolOrdinal?, Error> {
        ctx.fetchOne(predicate: #Predicate { $0.outpoint == outpoint }, includePendingChanges: true)
    }
}

@Model
final class RuneInfo {
    @Attribute(.unique) var id: String
    @Attribute(.unique) var name: String
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    static func fetchOneByName(ctx: ModelContext, name: String) -> Result<RuneInfo?, Error> {
        ctx.fetchOne(predicate: #Predicate { $0.name == name })
    }
}
