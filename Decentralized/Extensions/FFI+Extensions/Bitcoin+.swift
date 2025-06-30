//
//  Vin+.swift
//  Decentralized
//
//  Created by Nekilc on 2024/7/18.
//

import DecentralizedFFI
import Foundation

extension Txid {
    static func from(hex: String) -> Result<Txid, TxidParseError> {
        Result {
            try Txid.fromString(hex: hex)
        }
    }
}

extension TxIn: @retroactive Identifiable {
    public var id: String {
        "\(self.previousOutput.txid):\(self.previousOutput.vout)"
    }

    func fromHex(hex: String, witnessHex: String) -> TxIn? {
        newTxinFromHex(hex: hex, witnessHex: witnessHex)
    }
}

extension TxOut {
    func fromHex(hex: String) -> TxOut? {
        newTxoutFromHex(hex: hex)
    }

    func formattedScript(network: Network) -> String {
        if let addr = try? Address.fromScript(script: self.scriptPubkey, network: network).description {
            return addr
        }
        if let rune = try? extractRuneFromScript(script: self.scriptPubkey) {
            switch rune {
            case .edicts(let edicts):
                return edicts.first?.description ?? ""
            case .etching(let runeId):
                return runeId.description
            case .nothing:
                return self.scriptPubkey.description
            }
        }
        return self.scriptPubkey.description
    }
}

struct TxOutRow: Identifiable, Hashable, Equatable {
    static func == (lhs: TxOutRow, rhs: TxOutRow) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.inner.serializeHex)
    }

    let id: UUID = .init()
    let inner: TxOut

    func formattedScript(network: Network) -> String {
        self.inner.formattedScript(network: network)
    }

    var amount: Amount {
        return self.inner.value
    }

    func isMine(_ wallet: WalletStore)  -> Bool {
         wallet.isMine(self.inner.scriptPubkey)
    }
}

extension Psbt: @retroactive Equatable, @retroactive Hashable {
    public static func == (lhs: Psbt, rhs: Psbt) -> Bool {
        lhs.serializeHex() == rhs.serializeHex()
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.serializeHex())
    }

    static func fromHex(_ hex: String) -> Result<Psbt, PsbtParseError> {
        Result {
            try Psbt.fromHex(psbtHex: hex)
        }
    }

    func extractTransaction() -> Result<Transaction, ExtractTxError> {
        Result {
            try self.extractTx()
        }
    }
}

extension Amount: @retroactive Comparable {
    static let Zero: Amount = .fromSat(satoshi: 0)

    var formatted: String {
        "\(toSat().formattedSatoshis()) BTC"
    }

    public static func < (lhs: DecentralizedFFI.Amount, rhs: DecentralizedFFI.Amount) -> Bool {
        lhs.toSat() < rhs.toSat()
    }

    static func + (left: Amount, right: Amount) -> Amount {
        return Amount.fromSat(satoshi: left.toSat() + right.toSat())
    }

    static func - (left: Amount, right: Amount) -> Amount {
        return Amount.fromSat(satoshi: left.toSat() - right.toSat())
    }
}

extension Transaction: @retroactive Identifiable {
    public var id: Txid { self.computeTxid() }

    var vsize: UInt64 {
        self.vsize()
    }
}

extension FeeRate {
    static func from(satPerVb: UInt64) -> Result<FeeRate, FeeRateError> {
        Result {
            try FeeRate.fromSatPerVb(satVb: satPerVb)
        }
    }

    static func from(satPerKwu: UInt64) -> FeeRate {
        FeeRate.fromSatPerKwu(satKwu: satPerKwu)
    }
}

extension Address {
    static func from(address: String, network: Network) -> Result<Address, AddressParseError> {
        Result {
            try Address(address: address, network: network)
        }
    }

    static func from(script: Script, network: Network) -> Result<Address, AddressParseError> {
        Result {
            try Address.fromScript(script: script, network: network)
        }
    }
}

extension Amount {
    static func from(btc: Double) -> Result<Amount, ParseAmountError> {
        Result {
            try Amount.fromBtc(btc: btc)
        }
    }
}

extension OutPoint: Codable {
    enum CodingKeys: String, CodingKey {
        case txid
        case vout
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let txidString = try container.decode(String.self, forKey: .txid)

        let txid = try Txid.fromString(hex: txidString)
        let vout = try container.decode(UInt32.self, forKey: .vout)
        self.init(txid: txid, vout: vout)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.txid.description, forKey: .txid)
        try container.encode(self.vout, forKey: .vout)
    }
}

extension TxOut: Codable {
    enum CodingKeys: String, CodingKey {
        case value
        case scriptPubkey
        case serializeHex
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let value = try container.decode(UInt64.self, forKey: .value)
        let scriptPubkey = try container.decode(Data.self, forKey: .scriptPubkey)
        let serializeHex = try container.decode(String.self, forKey: .serializeHex)

        self.init(value: Amount.fromSat(satoshi: value), scriptPubkey: Script(rawOutputScript: scriptPubkey), serializeHex: serializeHex)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.value.toSat(), forKey: .value)
        try container.encode(self.scriptPubkey.toBytes(), forKey: .scriptPubkey)
        try container.encode(self.serializeHex, forKey: .serializeHex)
    }
}

extension DecentralizedFFI.Transaction {
    static func fromData(data: Data) -> Result<DecentralizedFFI.Transaction, TransactionError> {
        Result {
            try DecentralizedFFI.Transaction(transactionBytes: data)
        }
    }
}
