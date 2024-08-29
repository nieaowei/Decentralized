// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let person = try Person(json)

import Foundation

// MARK: - PersonElement

struct Utxo: Identifiable, Codable {
    var id: String {
        "\(txid):\(vout)"
    }

    let txid: String
    let vout: Int
    let status: Status
    let value: Int
}

// MARK: PersonElement convenience initializers and mutators

extension Utxo {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Utxo.self, from: data)
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
        status: Status? = nil,
        value: Int? = nil
    ) -> Utxo {
        return Utxo(
            txid: txid ?? self.txid,
            vout: vout ?? self.vout,
            status: status ?? self.status,
            value: value ?? self.value
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return try String(data: jsonData(), encoding: encoding)
    }
}


// MARK: - Status

struct Status: Codable {
    let confirmed: Bool
    @Default<Int> var blockHeight: Int
    @Default<String> var blockHash: String
    @Default<Int> var blockTime: Int

    enum CodingKeys: String, CodingKey {
        case confirmed
        case blockHeight = "block_height"
        case blockHash = "block_hash"
        case blockTime = "block_time"
    }
}

// MARK: Status convenience initializers and mutators

extension Status {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Status.self, from: data)
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
        confirmed: Bool? = nil,
        blockHeight: Int? = nil,
        blockHash: String? = nil,
        blockTime: Int? = nil
    ) -> Status {
        return Status(
            confirmed: confirmed ?? self.confirmed,
            blockHeight: blockHeight ?? self.blockHeight,
            blockHash: blockHash ?? self.blockHash,
            blockTime: blockTime ?? self.blockTime
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return try String(data: jsonData(), encoding: encoding)
    }
}

typealias Utxos = [Utxo]

extension Array where Element == Utxos.Element {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Utxos.self, from: data)
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
        return try String(data: jsonData(), encoding: encoding)
    }
}

// MARK: - Helper functions for creating encoders and decoders

func newJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
}

func newJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        encoder.dateEncodingStrategy = .iso8601
    }
    return encoder
}
