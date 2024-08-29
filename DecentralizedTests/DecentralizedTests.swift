//
//  DecentralizedTests.swift
//  DecentralizedTests
//
//  Created by Nekilc on 2024/7/17.
//

import Decentralized
import Foundation
import Testing


@propertyWrapper
struct Default<T: DefaultValue> {
    var wrappedValue: T.Value
}

extension Default: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = (try? container.decode(T.Value.self)) ?? T.defaultValue
    }
}

extension Default: Encodable where T: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

protocol DefaultValue {
    associatedtype Value: Codable
    static var defaultValue: Value { get }
}

extension String: DefaultValue {
    static var defaultValue = ""
}

extension Int: DefaultValue {
    static var defaultValue = 0
}

extension Bool: DefaultValue {
    static let defaultValue = false
}

extension KeyedDecodingContainer {
    func decode<T>(
        _ type: Default<T>.Type,
        forKey key: Key
    ) throws -> Default<T> where T: DefaultValue {
        try decodeIfPresent(type, forKey: key) ?? Default(wrappedValue: T.defaultValue)
    }
}
struct Status: Codable {
    @Default<Bool> var confirmed: Bool
//    let block_height: Int = 0
//    enum CodingKeys: String, CodingKey {
//        case confirmed
//        case blockHeight = "block_height"
//        case blockHash = "block_hash"
//        case blockTime = "block_time"
//    }
}


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
        confirmed: Bool? = nil
    ) -> Status {
        return Status(
            confirmed: confirmed ?? self.confirmed
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return try String(data: jsonData(), encoding: encoding)
    }
}

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

struct DecentralizedTests {
    @Test func toStatus() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        let text = "{\"confirmed1\":false}"

        let s = try Status(text)
        
        
    }
}
