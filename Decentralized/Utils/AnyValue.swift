//
//  AnyValue.swift
//  Decentralized
//
//  Created by Nekilc on 2024/10/12.
//

import Foundation

enum AnyValue: Codable {
    case integer(UInt64)
    case string(String)
    case double(Double)
    case boolean(Bool)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .integer(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .boolean(let value):
            try container.encode(value)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(UInt64.self) {
            self = .integer(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .boolean(boolValue)
        } else {
            throw DecodingError.typeMismatch(AnyValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Not support type"))
        }
    }
}
