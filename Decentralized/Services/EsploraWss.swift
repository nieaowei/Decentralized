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

enum EsploraWssData: Equatable {
    static func == (lhs: EsploraWssData, rhs: EsploraWssData) -> Bool {
        if case let EsploraWssData.newTx(a) = lhs {
            if case let .newTx(b) = rhs {
                return a.id == b.id
            }
        }
        if case let EsploraWssData.txConfirmed(a) = lhs {
            if case let EsploraWssData.txConfirmed(b) = rhs {
                return a == b
            }
        }
        if case let EsploraWssData.txRemoved(a) = lhs {
            if case let EsploraWssData.txRemoved(b) = rhs {
                return a.id == b.id
            }
        }
        if case let EsploraWssData.mempoolTx(a) = lhs {
            if case let EsploraWssData.mempoolTx(b) = rhs {
                return a.id == b.id
            }
        }
        return false
    }

    case mempoolTx(EsploraWssTx)
    case newTx(EsploraTx)
    case txConfirmed(String)
    case txRemoved(EsploraTx)
    case block(WssBlock)
}

class EsploraWss {
    enum Status: String {
        case connected, disconnected, connecting
    }

    enum SubscribeData {
        case address(String)
        case transaction(String)
        case mempoolBlock(UInt32)
    }

    private var id: UUID = .init()
    private var webSocketTask: URLSessionWebSocketTask
    private var urlSession: URLSession

    var handleFees: ((_ tx: Fees) -> Void)?
    var handleStatus: ((_ status: Status) -> Void)?

    private let logger: Logger = .init(subsystem: "app.decentralized", category: "wss")

    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let reconnectDelay = 2.0 // 初始重连延迟时间
    private var isCanceled = false
    var asyncStream: AsyncStream<EsploraWssData>?

    private var url: URL

    init(url: URL) {
        self.urlSession = URLSession(configuration: .default)
        self.url = url
        self.webSocketTask = urlSession.webSocketTask(with: url)
    }

    deinit {
        self.disconnect()
    }

    func connect() {
        id = UUID()
        webSocketTask = urlSession.webSocketTask(with: url)
        updateStatus(.connecting)
        webSocketTask.resume()
        wantStats()
        logger.info("\(self.url) Started")

        asyncStream = AsyncStream { continuation in
            self.receiveMessage(continuation: continuation)

//            continuation.onTermination = { @Sendable _ in
//                self.disconnect()
//            }
        }
    }

    func updateStatus(_ status: Status) {
        handleStatus?(status)
    }

    func reconnect() {
        if isCanceled {
            logger.info("\(self.url) Canceled")
            return
        }

        guard reconnectAttempts < maxReconnectAttempts else {
            logger.info("The count of attempts has reached the maximum")
            updateStatus(.disconnected)
            return
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + reconnectDelay * pow(2.0, Double(reconnectAttempts))) {
            self.logger.info("Try reconnect to \(self.reconnectAttempts + 1)")
            self.reconnectAttempts += 1
            self.connect()
        }
    }

    func disconnect() {
        isCanceled = true
        webSocketTask.cancel(with: .goingAway, reason: nil)
        updateStatus(.disconnected)
    }

    func subscribe(datas: [EsploraWss.SubscribeData]) {
        logger.info("Subscribe: \(datas)")
        for data in datas {
            switch data {
            case let .address(string):
                trackAddress(string)
            case let .transaction(string):
                trackTransaction(string)
            case let .mempoolBlock(index):
                trackMempoolBlock(index)
            }
        }
    }

    // todo use struct
    private func trackAddress(_ address: String) {
        sendMessage("{\"track-address\":\"\(address)\"}")
    }

    private func trackTransaction(_ txid: String) {
        sendMessage("{\"track-tx\":\"\(txid)\"}")
    }

    private func trackMempoolBlock(_ index: UInt32) {
        sendMessage("{\"track-mempool-block\":\(index)}")
    }

    private func wantStats() {
        sendMessage("{\"action\":\"want\",\"data\":[\"stats\",\"blocks\"]}")
    }

    private func sendMessage(_ message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)
        webSocketTask.send(message) { error in
            if let error = error {
                self.logger.error("Sending message: \(error)")
                self.updateStatus(.disconnected)
                self.reconnect()
            }
        }
    }

    private func handleMessage(_ text: String, _ continuation: AsyncStream<EsploraWssData>.Continuation) {
        do {
            let msg = try Message(text)

//            for tx in msg.transactions {
//                continuation.yield(.mempoolTx(tx))
//            }
            if let block = msg.block {
                continuation.yield(.block(block))
            }
//
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

            if let handle = handleFees {
                Task {
                    handle(msg.fees)
                }
            }

            if !msg.txConfirmed.isEmpty {
                continuation.yield(.txConfirmed(msg.txConfirmed))
            }

        } catch {
            logger.error("\(error)")
        }
    }

    private func receiveMessage(continuation: AsyncStream<EsploraWssData>.Continuation) {
        webSocketTask.receive { [self] result in
            switch result {
            case let .failure(error):
                self.logger.error("Receiving message: \(error)")
                self.updateStatus(.disconnected)
                continuation.finish()
                self.reconnect()
                return
            case let .success(message):

                self.updateStatus(.connected)
                self.reconnectAttempts = 0
                switch message {
                case let .string(text):
                    self.handleMessage(text, continuation)

                case let .data(data):
                    self.logger.info("Received binary data: \(data)")

                @unknown default:
                    continuation.finish()
                    return
                }
                self.receiveMessage(continuation: continuation)
            }
        }
    }
}

struct WssBlock: Codable {
    let id: String
    let height: UInt64
    let extras: WssBlockExtras
}

struct WssBlockExtras: Codable {
    let feeRange: [Double]
}

struct Message: Codable {
    var addressTransactions: [EsploraTx] = [] // add
//    var transactions: [EsploraWssTx] = []
    var addressRemovedTransactions: [EsploraTx] = [] // rbf
    var txConfirmed: String = ""
    var fees: Fees = .init(fastestFee: 0)
    let projectedBlockTransactions: ProjectedBlockTransactions?
    let block: WssBlock?

    enum CodingKeys: String, CodingKey {
        case addressTransactions = "address-transactions"
        case addressRemovedTransactions = "address-removed-transactions"
        case txConfirmed
        case fees
//        case transactions
        case projectedBlockTransactions = "projected-block-transactions"
        case block
    }
}

extension Message {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.transactions = try container.decodeIfPresent([EsploraWssTx].self, forKey: .transactions) ?? []
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

//    func with(
//        addressTransaction: [Tx] = [],
//        addressRemovedTransactions: [Tx] = [],
//        txConfirmed: String = ""
//    ) -> Message {
//        return Message()
//    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return try String(data: jsonData(), encoding: encoding)
    }
}

enum WantData: String {
    case stats, blocks
}

// MARK: - Person

struct Fees: Codable {
    let fastestFee: UInt64
}

// MARK: Person convenience initializers and mutators

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

    func with(
        fastestFee: UInt64? = nil
    ) -> Fees {
        return Fees(
            fastestFee: fastestFee ?? self.fastestFee
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return try String(data: jsonData(), encoding: encoding)
    }
}

struct ProjectedBlockTransactions: Codable {
    let index, sequence: Int
    let delta: Delta?
}

// MARK: ProjectedBlockTransactions convenience initializers and mutators

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

// MARK: - Delta

struct Delta: Codable {
    let added: [[Added]]
    let removed: [String]
    let changed: [[Added]]
}

// MARK: Delta convenience initializers and mutators

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

enum Added: Codable {
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
