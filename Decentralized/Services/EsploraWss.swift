//
//  MempoolService.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/23.
//

import BitcoinDevKit
import Foundation
import Observation
import OSLog

// @Observable
class EsploraWss {
    static let shared: EsploraWss = .init()

    enum Status {
        case connected, disconnected, connecting
    }

    enum Data {
        case address(String)
        case transaction(String)
    }

    private var webSocketTask: URLSessionWebSocketTask
    private var urlSession: URLSession

    var handleNewTx: ((_ tx: EsploraTx) async -> Void)?
    var handleConfirmedTx: ((_ tx: String) async -> Void)?
    var handleFees: ((_ tx: Fees) async -> Void)?
    var handleRemovedTx: ((_ tx: EsploraTx) async -> Void)?

    var status: Status = .disconnected

    let logger: Logger = .init(subsystem: "app.decentralized", category: "wss")

    init() {
        self.urlSession = URLSession(configuration: .default)
        let url = URL(string: "wss://mempool.space/api/v1/ws")!
        self.webSocketTask = urlSession.webSocketTask(with: url)
    }

    func connect() {
        status = .connecting

        webSocketTask.resume()
        wantStats()
        receiveMessage()
    }

    func disconnect() {
        webSocketTask.cancel(with: .goingAway, reason: nil)
    }

    func subscribe(datas: [EsploraWss.Data]) {
        for data in datas {
            switch data {
            case .address(let string):
                trackAddress(string)
            case .transaction(let string):
                trackTransaction(string)
            }
        }
    }

    private func trackAddress(_ address: String) {
        sendMessage("{\"track-address\":\"\(address)\"}")
    }

    private func trackTransaction(_ txid: String) {
        sendMessage("{\"track-tx\":\"\(txid)\"}")
    }

    private func wantStats() {
        sendMessage("{\"action\":\"want\",\"data\":[\"stats\"]}")
    }

    private func sendMessage(_ message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)
        webSocketTask.send(message) { error in
            if let error = error {
                self.logger.error("Sending message: \(error)")
            }
        }
    }

    private func receiveMessage() {
        webSocketTask.receive { [self] result in
            switch result {
            case .failure(let error):
                self.logger.error("Receiving message: \(error)")
                self.status = .disconnected
            case .success(let message):
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        self.status = .connected
                        do {
                            let msg = try Message(text)
                            for tx in msg.addressTransactions {
                                if let handle = self.handleNewTx {
                                    Task {
                                        await handle(tx)
                                    }
                                }
                            }

                            for tx in msg.addressRemovedTransactions {
                                if let handle = self.handleRemovedTx {
                                    Task {
                                        await handle(tx)
                                    }
                                }
                            }
                            if let handle = self.handleFees {
                                Task {
                                    await handle(msg.fees)
                                }
                            }

                            if !msg.txConfirmed.isEmpty {
                                if let handle = self.handleConfirmedTx {
                                    Task {
                                        await handle(msg.txConfirmed)
                                    }
                                }
                            }

                        } catch {
                            print(error)
                        }
                    }
                case .data(let data):
                    self.logger.info("Received binary data: \(data)")
                @unknown default:
                    fatalError()
                }
                self.receiveMessage()
            }
        }
    }
}

struct Message: Codable {
    var addressTransactions: [EsploraTx] = [] // add
    var addressRemovedTransactions: [EsploraTx] = [] // rbf
    var txConfirmed: String = ""
    var fees: Fees = .init(fastestFee: 0)

    enum CodingKeys: String, CodingKey {
        case addressTransactions = "address-transactions"
        case addressRemovedTransactions = "address-removed-transactions"
        case txConfirmed
        case fees
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.addressTransactions = try container.decodeIfPresent([EsploraTx].self, forKey: .addressTransactions) ?? []
        self.addressRemovedTransactions = try container.decodeIfPresent([EsploraTx].self, forKey: .addressRemovedTransactions) ?? []
        self.txConfirmed = try container.decodeIfPresent(String.self, forKey: .txConfirmed) ?? ""
        self.fees = try container.decodeIfPresent(Fees.self, forKey: .fees) ?? .init(fastestFee: 0)
    }
}

extension Message {
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
    let fastestFee: Int
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
        fastestFee: Int? = nil
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
