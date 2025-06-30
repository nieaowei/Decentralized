//
//  MempoolService.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/23.
//

import DecentralizedFFI
import Foundation
import Observation
import OSLog

enum EsploraWssData: Sendable, Equatable {
    static func == (lhs: EsploraWssData, rhs: EsploraWssData) -> Bool {
        switch (lhs, rhs) {
        case let (.newTx(a), .newTx(b)):
            return a.id == b.id
        case let (.txConfirmed(a), .txConfirmed(b)):
            return a == b
        case let (.txRemoved(a), .txRemoved(b)):
            return a.id == b.id
        case let (.mempoolTx(a), .mempoolTx(b)):
            return a.id == b.id
        case let (.block(a), .block(b)):
            return a.id == b.id
        default:
            return false
        }
    }

    case mempoolTx(EsploraWssTx)
    case newTx(EsploraTx)
    case txConfirmed(String)
    case txRemoved(EsploraTx)
    case block(WssBlock)
}

actor EsploraWss {
    enum Status: String, Sendable {
        case connected, disconnected, connecting
    }

    enum SubscribeData: Sendable {
        case address(String)
        case transaction(String)
        case mempoolBlock(UInt32)
    }

    private var id: UUID = .init()
    private var webSocketTask: URLSessionWebSocketTask
    private var urlSession: URLSession

    // 使用 @Sendable 闭包确保并发安全
    var onFees: (@Sendable (_ tx: Fees) -> Void)?
    var onStatus: (@Sendable (_ status: Status) -> Void)?

    private let logger: Logger = .init(subsystem: "app.decentralized", category: "wss")

    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let reconnectDelay = 2.0
    private var isCanceled = false
    var asyncStream: AsyncStream<EsploraWssData>?

    private var url: URL

    init(url: URL) {
        self.urlSession = URLSession(configuration: .default)
        self.url = url
        self.webSocketTask = urlSession.webSocketTask(with: url)
    }

    func setOnFees(_ onFees: @escaping @Sendable (_ tx: Fees) -> Void) {
        self.onFees = onFees
    }

    func setOnStatus(_ onStatus: @escaping @Sendable (_ status: Status) -> Void) {
        self.onStatus = onStatus
    }

    func connect() async {
        id = UUID()
        webSocketTask = urlSession.webSocketTask(with: url)

        logger.info("Wss connecting: \(self.url) [\(self.id)]")

        await handleStatus(.connecting)
        webSocketTask.resume()
        await wantStats()

        asyncStream = AsyncStream { continuation in
            Task {
                await self.receiveMessage(continuation: continuation)
            }
        }
    }

    private func handleStatus(_ status: Status) async {
        onStatus?(status)
    }

    private func handleFees(_ fees: Fees) async {
        onFees?(fees)
    }

    func reconnect() async {
        if isCanceled {
            return
        }

        guard reconnectAttempts < maxReconnectAttempts else {
            logger.info("The count of attempts has reached the maximum")
            await handleStatus(.disconnected)
            return
        }

        do {
            try await Task.sleep(nanoseconds: UInt64(reconnectDelay * pow(2.0, Double(reconnectAttempts)) * 1_000_000_000))
            self.logger.info("Try reconnect to \(self.reconnectAttempts + 1)")

            reconnectAttempts += 1
            await connect()
        } catch {
            logger.error("Sleep interrupted: \(error)")
        }
    }

    func disconnect() async {
        isCanceled = true
        webSocketTask.cancel(with: .goingAway, reason: nil)
        await handleStatus(.disconnected)
        logger.info("Wss disconnected: \(self.url) [\(self.id)]")

    }

    func subscribe(datas: [EsploraWss.SubscribeData]) async {
        logger.info("Subscribe: \(datas)")
        for data in datas {
            switch data {
            case let .address(string):
                await trackAddress(string)
            case let .transaction(string):
                await trackTransaction(string)
            case let .mempoolBlock(index):
                await trackMempoolBlock(index)
            }
        }
    }

    private func trackAddress(_ address: String) async {
        await sendMessage("{\"track-address\":\"\(address)\"}")
    }

    private func trackTransaction(_ txid: String) async {
        await sendMessage("{\"track-tx\":\"\(txid)\"}")
    }

    private func trackMempoolBlock(_ index: UInt32) async {
        await sendMessage("{\"track-mempool-block\":\(index)}")
    }

    private func wantStats() async {
        await sendMessage("{\"action\":\"want\",\"data\":[\"stats\",\"blocks\"]}")
    }

    private func sendMessage(_ message: String) async {
        let message = URLSessionWebSocketTask.Message.string(message)
        do {
            try await webSocketTask.send(message)
        } catch {
            logger.error("Sending message: \(error)")
            await handleStatus(.disconnected)
            await reconnect()
        }
    }

    private func handleMessage(_ text: String, _ continuation: AsyncStream<EsploraWssData>.Continuation) async {
        do {
            let msg = try Message(text)

            if let block = msg.block {
                continuation.yield(.block(block))
            }

            if let txs = msg.projectedBlockTransactions {
                if let delta = txs.delta {
                    for tx in delta.added {
                        if let tx = tx.toEsploraWssTx() {
                            if tx.isAnyoneCanPay() {
                                continuation.yield(.mempoolTx(tx))
                            }
                        }
                    }
                }
            }

            for tx in msg.addressTransactions {
                continuation.yield(.newTx(tx))
            }

            for tx in msg.addressRemovedTransactions {
                continuation.yield(.txRemoved(tx))
            }

            await handleFees(msg.fees)

            if !msg.txConfirmed.isEmpty {
                continuation.yield(.txConfirmed(msg.txConfirmed))
            }

        } catch {
            logger.error("\(error)")
        }
    }

    private func receiveMessage(continuation: AsyncStream<EsploraWssData>.Continuation) async {
        do {
            let message = try await webSocketTask.receive()

            await handleStatus(.connected)
            reconnectAttempts = 0

            switch message {
            case let .string(text):
                await handleMessage(text, continuation)

            case let .data(data):
                logger.info("Received binary data: \(data)")

            @unknown default:
                continuation.finish()
                return
            }
            await receiveMessage(continuation: continuation)

        } catch {
            logger.error("Receiving message: \(error)")
            await handleStatus(.disconnected)
            continuation.finish()
            await reconnect()
            return
        }
    }
}

struct WssBlock: Sendable, Codable {
    let id: String
    let height: UInt64
    let extras: WssBlockExtras
}

struct WssBlockExtras: Sendable, Codable {
    let feeRange: [Double]
}

struct Message: Sendable, Codable {
    var addressTransactions: [EsploraTx] = []
    var addressRemovedTransactions: [EsploraTx] = []
    var txConfirmed: String = ""
    var fees: Fees = .init(fastestFee: 0)
    let projectedBlockTransactions: ProjectedBlockTransactions?
    let block: WssBlock?

    enum CodingKeys: String, CodingKey {
        case addressTransactions = "address-transactions"
        case addressRemovedTransactions = "address-removed-transactions"
        case txConfirmed
        case fees
        case projectedBlockTransactions = "projected-block-transactions"
        case block
    }
}

extension Message {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.addressTransactions = try container.decodeIfPresent([EsploraTx].self, forKey: .addressTransactions) ?? []
        self.addressRemovedTransactions = try container.decodeIfPresent([EsploraTx].self, forKey: .addressRemovedTransactions) ?? []
        self.txConfirmed = try container.decodeIfPresent(String.self, forKey: .txConfirmed) ?? ""
        self.fees = try container.decodeIfPresent(Fees.self, forKey: .fees) ?? .init(fastestFee: 0)
        self.projectedBlockTransactions = try container.decodeIfPresent(ProjectedBlockTransactions.self, forKey: .projectedBlockTransactions)
        self.block = try container.decodeIfPresent(WssBlock.self, forKey: .block)
    }

    init(data: Data) throws {
        self = try newJSONDecoder().decode(Message.self, from: data)
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

enum WantData: String, Sendable {
    case stats, blocks
}

struct Fees: Sendable, Codable {
    let fastestFee: UInt64
}

extension Fees {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Fees.self, from: data)
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

    func with(fastestFee: UInt64? = nil) -> Fees {
        return Fees(fastestFee: fastestFee ?? self.fastestFee)
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return try String(data: jsonData(), encoding: encoding)
    }
}

struct ProjectedBlockTransactions: Sendable, Codable {
    let index, sequence: Int
    let delta: Delta?
}

extension ProjectedBlockTransactions {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(ProjectedBlockTransactions.self, from: data)
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
        index: Int? = nil,
        sequence: Int? = nil,
        delta: Delta? = nil
    ) -> ProjectedBlockTransactions {
        return ProjectedBlockTransactions(
            index: index ?? self.index,
            sequence: sequence ?? self.sequence,
            delta: delta ?? self.delta
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return try String(data: jsonData(), encoding: encoding)
    }
}

struct Delta: Sendable, Codable {
    let added: [[Added]]
    let removed: [String]
    let changed: [[Added]]
}

extension Delta {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Delta.self, from: data)
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
        added: [[Added]]? = nil,
        removed: [String]? = nil,
        changed: [[Added]]? = nil
    ) -> Delta {
        return Delta(
            added: added ?? self.added,
            removed: removed ?? self.removed,
            changed: changed ?? self.changed
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return try String(data: jsonData(), encoding: encoding)
    }
}

enum Added: Sendable, Codable {
    case uint(UInt64)
    case double(Double)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(UInt64.self) {
            self = .uint(x)
            return
        }
        if let x = try? container.decode(Double.self) {
            self = .double(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        throw DecodingError.typeMismatch(Added.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for Added"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .uint(x):
            try container.encode(x)
        case let .double(x):
            try container.encode(x)
        case let .string(x):
            try container.encode(x)
        }
    }
}

extension Added {
    func asString() -> String? {
        if case let .string(s) = self {
            return s
        }
        return nil
    }

    func asUint64() -> UInt64? {
        if case let .uint(s) = self {
            return s
        }
        return nil
    }

    func asDouble() -> Double? {
        if case let .double(s) = self {
            return s
        }
        return nil
    }
}

extension [Added] {
    func toEsploraWssTx() -> EsploraWssTx? {
        if self.count >= 7 {
            return EsploraWssTx(txid: self[0].asString()!, flags: self[5].asUint64()!, feeRate: self[4].asDouble() ?? Double(self[4].asUint64()!))
        }
        return nil
    }
}
