//
//  Default.swift
//  Decentralized
//
//  Created by Nekilc on 2024/7/17.
//

import Foundation

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
    associatedtype Value: Codable, Sendable
    static var defaultValue: Value { get }
}

extension String: DefaultValue {
    static let defaultValue = ""
}

extension Int: DefaultValue {
    static let defaultValue = 0
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
