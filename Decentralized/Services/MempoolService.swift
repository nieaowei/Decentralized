//
//  MempoolService.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/23.
//

import BitcoinDevKit
import Foundation
import Observation

enum Signal {
    case newTx([String])
    case rmTx([String])
    case confirmedTx([String])
}

@Observable
class MempoolService {
    enum Status {
        case connected, disconnected, connecting
    }

    @ObservationIgnored
    private var webSocketTask: URLSessionWebSocketTask?
    @ObservationIgnored
    private var urlSession: URLSession

    var newTranactions: [String] = []
    var rmTranactions: [String] = []
    var confirmedTranactions: [String] = []
    var fastfee: Int = 0

    var status: Status = .disconnected

    init() {
        self.urlSession = URLSession(configuration: .default)
    }

    func connect() {
        status = .connecting
        guard let url = URL(string: "wss://mempool.space/api/v1/ws") else { return }
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        wantStats()
        receiveMessage()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }

    func trackAddress(_ address: String) {
        sendMessage("{\"track-address\":\"\(address)\"}")
    }

    func trackTransaction(_ txid: String) {
        sendMessage("{\"track-tx\":\"\(txid)\"}")
    }

    func wantStats() {
        sendMessage("{\"action\":\"want\",\"data\":[\"stats\"]}")
    }

    func sendMessage(_ message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("Error sending message: \(error)")
            }
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("Error receiving message: \(error)")
                self?.status = .disconnected
            case .success(let message):
//                print("Recv msg")
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        self?.status = .connected
                        do {
//                            print(text)
                            let msg = try Message(text)

                            for tx in msg.addressTransactions {
                                self?.newTranactions.append(tx.txid)
                            }

                            for tx in msg.addressRemovedTransactions {
                                self?.rmTranactions.append(tx.txid)
                            }

                            self?.fastfee = msg.fees.fastestFee

                            if !msg.txConfirmed.isEmpty {
                                self?.confirmedTranactions.append(msg.txConfirmed)
                            }

                        } catch {
                            print(error)
                        }
                    }
                case .data(let data):
                    print("Received binary data: \(data)")
                @unknown default:
                    fatalError()
                }
                // Continue to receive messages
                self?.receiveMessage()
            }
        }
    }
}

struct Message: Codable {
    var addressTransactions: [Tx] = [] // add
    var addressRemovedTransactions: [Tx] = [] // rbf
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
        self.addressTransactions = try container.decodeIfPresent([Tx].self, forKey: .addressTransactions) ?? []
        self.addressRemovedTransactions = try container.decodeIfPresent([Tx].self, forKey: .addressRemovedTransactions) ?? []
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

