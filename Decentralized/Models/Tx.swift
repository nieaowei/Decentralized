// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let person = try Person(json)

import Foundation

// MARK: - PersonElement

struct Tx: Identifiable, Codable {
    var id: String {
        self.txid
    }

    let txid: String
    let version, locktime: Int
    let vin: [Vin]
    let vout: [Vout]
    let size, weight, sigops, fee: Int
    let status: Status
}

// MARK: PersonElement convenience initializers and mutators

extension Tx {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Tx.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: Data(contentsOf: url))
    }

    func with(
        txid: String? = nil,
        version: Int? = nil,
        locktime: Int? = nil,
        vin: [Vin]? = nil,
        vout: [Vout]? = nil,
        size: Int? = nil,
        weight: Int? = nil,
        sigops: Int? = nil,
        fee: Int? = nil,
        status: Status? = nil
    ) -> Tx {
        return Tx(
            txid: txid ?? self.txid,
            version: version ?? self.version,
            locktime: locktime ?? self.locktime,
            vin: vin ?? self.vin,
            vout: vout ?? self.vout,
            size: size ?? self.size,
            weight: weight ?? self.weight,
            sigops: sigops ?? self.sigops,
            fee: fee ?? self.fee,
            status: status ?? self.status
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return try String(data: self.jsonData(), encoding: encoding)
    }
}

// MARK: - Vin

struct Vin: Codable {
    let txid: String
    let vout: Int
    let prevout: Vout
    let scriptsig, scriptsigASM: String
    let witness: [String]?
    let isCoinbase: Bool
    let sequence: Int
    let innerWitnessscriptASM, innerRedeemscriptASM: String?

    enum CodingKeys: String, CodingKey {
        case txid, vout, prevout, scriptsig
        case scriptsigASM = "scriptsig_asm"
        case witness
        case isCoinbase = "is_coinbase"
        case sequence
        case innerWitnessscriptASM = "inner_witnessscript_asm"
        case innerRedeemscriptASM = "inner_redeemscript_asm"
    }
}

extension Vin: Identifiable {
    public var id: String {
        "\(self.txid):\(self.vout)"
    }
}

// MARK: Vin convenience initializers and mutators

extension Vin {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Vin.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: Data(contentsOf: url))
    }

    func with(
        txid: String? = nil,
        vout: Int? = nil,
        prevout: Vout? = nil,
        scriptsig: String? = nil,
        scriptsigASM: String? = nil,
        witness: [String]?? = nil,
        isCoinbase: Bool? = nil,
        sequence: Int? = nil,
        innerWitnessscriptASM: String?? = nil,
        innerRedeemscriptASM: String?? = nil
    ) -> Vin {
        return Vin(
            txid: txid ?? self.txid,
            vout: vout ?? self.vout,
            prevout: prevout ?? self.prevout,
            scriptsig: scriptsig ?? self.scriptsig,
            scriptsigASM: scriptsigASM ?? self.scriptsigASM,
            witness: witness ?? self.witness,
            isCoinbase: isCoinbase ?? self.isCoinbase,
            sequence: sequence ?? self.sequence,
            innerWitnessscriptASM: innerWitnessscriptASM ?? self.innerWitnessscriptASM,
            innerRedeemscriptASM: innerRedeemscriptASM ?? self.innerRedeemscriptASM
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return try String(data: self.jsonData(), encoding: encoding)
    }
}

// MARK: - Vout

struct Vout: Codable, Identifiable {
    let scriptpubkey, scriptpubkeyASM: String
    let scriptpubkeyType: ScriptpubkeyType
    let scriptpubkeyAddress: String?
    let value: UInt64
    var id: UUID = UUID()
    
    enum CodingKeys: String, CodingKey {
        case scriptpubkey
        case scriptpubkeyASM = "scriptpubkey_asm"
        case scriptpubkeyType = "scriptpubkey_type"
        case scriptpubkeyAddress = "scriptpubkey_address"
        case value
    }
}



// MARK: Vout convenience initializers and mutators

extension Vout {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Vout.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: Data(contentsOf: url))
    }

    func with(
        scriptpubkey: String? = nil,
        scriptpubkeyASM: String? = nil,
        scriptpubkeyType: ScriptpubkeyType? = nil,
        scriptpubkeyAddress: String?? = nil,
        value: UInt64? = nil
    ) -> Vout {
        return Vout(
            scriptpubkey: scriptpubkey ?? self.scriptpubkey,
            scriptpubkeyASM: scriptpubkeyASM ?? self.scriptpubkeyASM,
            scriptpubkeyType: scriptpubkeyType ?? self.scriptpubkeyType,
            scriptpubkeyAddress: scriptpubkeyAddress ?? self.scriptpubkeyAddress,
            value: value ?? self.value
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return try String(data: self.jsonData(), encoding: encoding)
    }
}

enum ScriptpubkeyType: String, Codable {
    case opReturn = "op_return"
    case p2Pkh = "p2pkh"
    case p2Sh = "p2sh"
    case v0P2Wpkh = "v0_p2wpkh"
    case v0P2Wsh = "v0_p2wsh"
    case v1P2Tr = "v1_p2tr"
}

typealias Txs = [Tx]

extension Array where Element == Txs.Element {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Txs.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: Data(contentsOf: url))
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return try String(data: self.jsonData(), encoding: encoding)
    }
}

extension Tx {
//    var changeBalance: Amount{
//        self.
//    }
}

import BitcoinDevKit

// extension Tx: BitcoinDevKit.TransactionProtocol {
//    func input()  -> [TxIn]
//
//    func isCoinbase()  -> Bool{
//
//    }
//
//    func isExplicitlyRbf()  -> Bool
//
//    func isLockTimeEnabled()  -> Bool
//
//    func lockTime()  -> UInt32
//
//    func output()  -> [TxOut]
//
//    func serialize()  -> [UInt8]
//
//    func totalSize()  -> UInt64
//
//    func txid()  -> String
//
//    func version()  -> Int32
//
//    func vsize()  -> UInt64
//
//    func weight()  -> UInt64
// }
