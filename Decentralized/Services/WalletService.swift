//
//  BDKService.swift
//
//  Created by Nekilc on 2024/5/24.
//

import DecentralizedFFI
import Foundation
import Observation
import OSLog

enum WalletMode: String, Codable, CaseIterable {
    case xverse
    case peek
}

enum WalletType: String, Codable, CaseIterable {
    case pay
    case ordinal
}

@Observable
class SyncClient {
    var inner: SyncClientInner

    init(inner: SyncClientInner) {
        self.inner = inner
    }

    func broadcast(_ tx: Transaction) throws -> String {
        try self.inner.broadcast(tx)
    }

    func sync(_ syncRequest: SyncRequest) throws -> Update {
        try self.inner.sync(syncRequest)
    }

    func getTx(_ txid: String) throws -> Transaction {
        try self.inner.getTx(txid)
    }
}

enum SyncClientInner {
    case esplora(EsploraClient)
    case electrum(ElectrumClient)

    func broadcast(_ tx: Transaction) throws -> String {
        return switch self {
        case .esplora(let esploraClient):
            try {
                try esploraClient.broadcast(transaction: tx)
                return tx.id
            }()
        case .electrum(let electrumClient):
            try electrumClient.broadcast(transaction: tx)
        }
    }

    func sync(_ syncRequest: SyncRequest) throws -> Update {
        return switch self {
        case .esplora(let esploraClient):
            try {
                logger.info("esplora sync")
                return try esploraClient.sync(request: syncRequest, parallelRequests: 10)
            }()
        case .electrum(let electrumClient):
            try {
                logger.info("electrum sync")
                return try electrumClient.sync(request: syncRequest, batchSize: 10, fetchPrevTxouts: true)
            }()
        }
    }

    func getTx(_ txid: String) throws -> Transaction {
        return switch self {
        case .esplora(let esploraClient):
            try esploraClient.getTx(txid: txid)
        case .electrum(let electrumClient):
            try electrumClient.getTx(txid: txid)
        }
    }
}

// class WalletSyncScriptInspector: SyncScriptInspector {
//    private let updateProgress: (UInt64, UInt64) -> Void
//    private var inspectedCount: UInt64 = 0
//    private var totalCount: UInt64 = 0
//
//    init(updateProgress: @escaping (UInt64, UInt64) -> Void) {
//        self.updateProgress = updateProgress
//    }
//
//    func inspect(script: Script, total: UInt64) {
//        self.totalCount = total
//        self.inspectedCount += 1
//        self.updateProgress(self.inspectedCount, self.totalCount)
//    }
// }

enum WalletError: Error {
    case walletNotFound
    case storeNotFound
    case signError
    case blockchainConfigNotFound
    case noOutput
}

struct WalletService {
    private var network: Networks
    private let syncClient: SyncClient

    private var payWallet: Wallet
    private var payConn: Connection
    private var payAddress: Address

    private var ordiWallet: Wallet
    private var ordiConn: Connection
    private var ordiAddress: Address

    private let logger: Logger = AppLogger(cat: "WalletService")

    init(
        words: String,
        mode: WalletMode,
        network: Networks,
        syncClient: SyncClient
    ) throws {
        self.network = network
        self.syncClient = syncClient
        ((self.payWallet, self.payConn, self.payAddress), (self.ordiWallet, self.ordiConn, self.ordiAddress)) = try WalletService.create(words: words, mode: mode, network: network)
    }

    init(
        network: Networks,
        syncClient: SyncClient
    ) throws {
        self.network = network
        self.syncClient = syncClient
        ((self.payWallet, self.payConn, self.payAddress), (self.ordiWallet, self.ordiConn, self.ordiAddress)) = try WalletService.loadWalletFromBackup(network: network)
    }

    func getPayAddress() -> Address {
        return self.payAddress
    }

    func getOrdiAddress() -> Address {
        return self.ordiAddress
    }

    func getBalance() -> Balance {
        return self.payWallet.balance()
    }

    func getTransactions() -> [CanonicalTx] {
        return self.payWallet.transactions()
    }

    func getUtxos() -> [LocalOutput] {
        return self.payWallet.listUnspent()
    }

    func getAllUtxos() -> [LocalOutput] {
        return self.payWallet.listOutput()
    }

    func getOutputs() -> [LocalOutput] {
        return self.payWallet.listOutput()
    }

    func getTxOut(op: OutPoint) -> TxOut? {
        return self.payWallet.getTxout(outpoint: op)
    }

    func getUtxo(op: OutPoint) -> LocalOutput? {
        return self.payWallet.getUtxo(outpoint: op)
    }

    func isMine(script: Script) -> Bool {
        return self.payWallet.isMine(script: script)
    }

    private static func createDescriptor(words: String, mode: WalletMode, network: Networks) throws -> (Descriptor, Descriptor) {
        let mnemonic = try Mnemonic.fromString(mnemonic: words)

        let paySecretKey = DescriptorSecretKey(
            network: network.toBitcoinNetwork(),
            mnemonic: mnemonic,
            password: nil
        )

        let payDescriptor = switch mode {
        case .xverse:
            try Descriptor.newBip49(
                secretKey: paySecretKey.derivePriv(path: DerivationPath(path: "m/49'/0'/0'/0/0")),
                keychainKind: .external,
                network: network.toBitcoinNetwork()
            )
        case .peek:
            try Descriptor.newBip86(
                secretKey: paySecretKey.derivePriv(path: DerivationPath(path: "m/86'/0'/0'/0/0")),
                keychainKind: .external,
                network: network.toBitcoinNetwork()
            )
        }

        let ordiDescriptor = try Descriptor.newBip86(
            secretKey: paySecretKey.derivePriv(path: DerivationPath(path: "m/86'/0'/0'/0/1")),
            keychainKind: .external,
            network: network.toBitcoinNetwork()
        )

        return (payDescriptor, ordiDescriptor)
    }

    static func create(words: String?, mode: WalletMode, network: Networks) throws -> ((Wallet, Connection, Address), (Wallet, Connection, Address)) {
        var words12: String

        if let words = words, !words.isEmpty {
            words12 = words
        } else {
            let mnemonic = Mnemonic(wordCount: WordCount.words12)
            words12 = mnemonic.description
        }

        let (payDescriptor, ordiDescriptor) = try createDescriptor(words: words12, mode: mode, network: network)

        let documentsDirectoryURL = FileManager.default.getDocumentsDirectoryPath()
        let payWalletDataDirectoryURL = documentsDirectoryURL.appendingPathComponent("pay_\(network.rawValue).sqlite")
        let payPersistenceBackendPath = payWalletDataDirectoryURL.path

        let payDb = try Connection(path: payPersistenceBackendPath)

        let payWallet = try Wallet.createSingle(
            descriptor: payDescriptor,
            network: network.toCustomNetwork(),
            connection: payDb
        )

        let ordiWalletDataDirectoryURL = documentsDirectoryURL.appendingPathComponent("ordi_\(network.rawValue).sqlite")
        let ordiPersistenceBackendPath = ordiWalletDataDirectoryURL.path

        let ordiDb = try! Connection(path: ordiPersistenceBackendPath)

        let ordiWallet = try Wallet.createSingle(
            descriptor: ordiDescriptor,
            network: network.toCustomNetwork(),
            connection: ordiDb
        )

//        let payAddress = payWallet.peekAddress(keychainKind: .external, index: 0).address
        let payAddress = payWallet.revealNextAddress(keychainKind: .external).address
//        var ordiAddress = ordiWallet.peekAddress(keychainKind: .external, index: 0).address
        let ordiAddress = ordiWallet.revealNextAddress(keychainKind: .external).address
//        if mode == .peek {
//            ordiAddress = ordiWallet.peekAddress(keychainKind: .external, index: 1).address
//            _ = ordiWallet.revealAddressesTo(keychainKind: .external, index: 1)
//        }

        _ = try payWallet.persist(connection: payDb)

        _ = try ordiWallet.persist(connection: ordiDb)

        let backupInfo = BackupInfo(
            mnemonic: words12,
            mode: mode
        )
        _ = try KeyChainService.saveBackupInfo(backupInfo)

        return ((payWallet, payDb, payAddress), (ordiWallet, ordiDb, ordiAddress))
    }

    private static func loadWallet(mode: WalletMode, network: Networks, payDescriptor: Descriptor, ordiDescriptor: Descriptor) throws -> ((Wallet, Connection, Address), (Wallet, Connection, Address)) {
        let documentsDirectoryURL = FileManager.default.getDocumentsDirectoryPath()

        let payWalletDataDirectoryURL = documentsDirectoryURL.appendingPathComponent("pay_\(network.rawValue).sqlite")
        let payPersistenceBackendPath = payWalletDataDirectoryURL.path

        let db = try Connection(path: payPersistenceBackendPath)

        let payWallet = try Wallet.load(
            descriptor: payDescriptor,
            changeDescriptor: nil,
            connection: db
        )

        let ordiWalletDataDirectoryURL = documentsDirectoryURL.appendingPathComponent("ordi_\(network.rawValue).sqlite")
        let ordiPersistenceBackendPath = ordiWalletDataDirectoryURL.path
        let ordiDb = try Connection(path: ordiPersistenceBackendPath)

        let ordiWallet = try Wallet.load(
            descriptor: ordiDescriptor,
            changeDescriptor: nil,
            connection: ordiDb
        )

        let payAddr = payWallet.peekAddress(keychainKind: .external, index: 0).address
        let ordiAddr = ordiWallet.peekAddress(keychainKind: .external, index: 0).address
//        if mode == .peek {
//            ordiAddr = ordiWallet.peekAddress(keychainKind: .external, index: 1).address
//        }

        return ((payWallet, db, payAddr), (ordiWallet, ordiDb, ordiAddr))
    }

    private static func loadWalletFromBackup(network: Networks) throws -> ((Wallet, Connection, Address), (Wallet, Connection, Address)) {
        let backupInfo = try KeyChainService.getBackupInfo()

        if !FileManager.default.fileExists(atPath: FileManager.default.getDocumentsDirectoryPath().appendingPathComponent("pay_\(network.rawValue).sqlite").path) {
            return try self.create(words: backupInfo.mnemonic, mode: backupInfo.mode, network: network)
        }

        let (payDescriptor, ordiDescriptor) = try createDescriptor(words: backupInfo.mnemonic, mode: backupInfo.mode, network: network)

        return try self.loadWallet(mode: backupInfo.mode, network: network, payDescriptor: payDescriptor, ordiDescriptor: ordiDescriptor)
    }

    static func deleteAllWallet() throws {
        try KeyChainService.deleteBackupInfo()
        try FileManager.default.deleteAllContentsInDocumentsDirectory()
    }

    func finish(_ txbuiler: TxBuilder) -> Result<Psbt, CreateTxError> {
        Result {
            try txbuiler.finish(wallet: self.payWallet)
        }
    }

    func sign(_ psbt: Psbt, walletType: WalletType = .pay) -> Result<Bool, SignerError> {
        Result {
            switch walletType {
            case .pay: try self.payWallet.sign(psbt: psbt)
            case .ordinal: try self.ordiWallet.sign(psbt: psbt)
            }
        }
    }

    func inspector(inspectedCount: UInt64, total: UInt64) {
        //        print(inspectedCount, total)
    }

    func sync() async throws {
        let syncRequest = try payWallet.startSyncWithRevealedSpks().build()

        self.logger.info("Syning")

        let update = try syncClient.sync(syncRequest)

        self.logger.info("Update")
        try self.payWallet.applyUpdate(update: update)
        self.logger.info("Persist")
        _ = try self.payWallet.persist(connection: self.payConn)
    }

    func calculateFee(_ tx: DecentralizedFFI.Transaction) -> Amount {
        do {
            return try self.payWallet.calculateFee(tx: tx)
        } catch {
            return .Zero
        }
    }

    func calculateFeeRate(_ tx: DecentralizedFFI.Transaction) -> FeeRate {
        do {
            return try self.payWallet.calculateFeeRate(tx: tx)
        } catch {
            return try! .fromSatPerVb(satPerVb: 0)
        }
    }

    func sentAndReceived(_ tx: DecentralizedFFI.Transaction) -> SentAndReceivedValues {
        self.payWallet.sentAndReceived(tx: tx)
    }

    func broadcast(_ tx: DecentralizedFFI.Transaction) -> Result<String, Error> {
        let txid = Result {
            try self.syncClient.broadcast(tx)
        }
        guard case .success(let txid) = txid else {
            return .failure(txid.err()!)
        }

        self.payWallet.applyUnconfirmedTxs(txAndLastSeens: [TransactionAndLastSeen(tx: tx, lastSeen: UInt64(Date().timeIntervalSince1970))])

        let ok = Result {
            try self.payWallet.persist(connection: self.payConn)
        }
        guard case .success(let ok) = ok else {
            return .failure(ok.err()!)
        }

        return .success(txid)
    }

    func insertTxOut(op: OutPoint, txout: TxOut) {
        self.payWallet.insertTxout(outpoint: op, txout: txout)
    }
}

// struct BDKClient {
//    let loadWallet: () throws -> Void
//    let deleteWallet: () throws -> Void
//    let createWallet: (String?, WalletMode) throws -> Void
//    let getBalance: () throws -> Balance
//    let transactions: () throws -> [CanonicalTx]
//    let utxos: () throws -> [LocalOutput]
//    let outputs: () throws -> [LocalOutput]
//    let sync: () async throws -> Void
//    let fullScan: () async throws -> Void
//    let getPayAddress: () throws -> Address
//    let getOrdiAddress: () throws -> Address
//    let calculateFee: (Transaction) throws -> UInt64
//    let calculateFeeRate: (Transaction) throws -> UInt64
//    let sentAndReceived: (Transaction) throws -> SentAndReceivedValues
//    let getBackupInfo: () throws -> BackupInfo
//    let buildTx: (_ tx: TxBuilder) throws -> Transaction
//    let sign: (_ tx: TxBuilder) throws -> (Bool, Psbt)
//    let getChangeAmount: (_ tx: TxBuilder) throws -> Amount
// }

// extension BDKClient {
//    static let live = Self(
//        loadWallet: { try BDKService.shared.loadWalletFromBackup() },
//        deleteWallet: { try BDKService.shared.deleteWallet() },
//        createWallet: { words, mode in try BDKService.shared.createWallet(words: words, mode: mode) },
//        getBalance: { try BDKService.shared.getBalance() },
//        transactions: { try BDKService.shared.transactions() },
//        utxos: { try BDKService.shared.utxos() },
//        outputs: { try BDKService.shared.outputs() },
//        sync: { try await BDKService.shared.sync() },
//        fullScan: { try await BDKService.shared.fullScan() },
//        getPayAddress: { BDKService.shared.getPayAddress() },
//        getOrdiAddress: { BDKService.shared.getOrdiAddress() },
//
//        calculateFee: { tx in try BDKService.shared.calculateFee(tx: tx) },
//        calculateFeeRate: { tx in try BDKService.shared.calculateFeeRate(tx: tx) },
//        sentAndReceived: { tx in try BDKService.shared.sentAndReceived(tx: tx) },
//
//        getBackupInfo: { try BDKService.shared.getBackupInfo() },
//        buildTx: { tx in try BDKService.shared.buildTx(tx) },
//        sign: { tx in try BDKService.shared.sign(tx) },
//        getChangeAmount: { tx in try BDKService.shared.getChangeAmount(tx) }
//    )
// }

//
// #if DEBUG
//    extension BDKClient {
//        static let mock = Self(
//            loadWallet: {},
//            deleteWallet: {},
//            createWallet: { _ in },
//            getBalance: { mockBalance },
//            getTransactions: { mockTransactionDetails },
//            sync: {},
//            getAddress: { "tb1pd8jmenqpe7rz2mavfdx7uc8pj7vskxv4rl6avxlqsw2u8u7d4gfs97durt" },
//            send: { _, _, _ in },
//            buildTransaction: { _, _, _ in
//                let pb64 = """
//                cHNidP8BAIkBAAAAAeaWcxp4/+xSRJ2rhkpUJ+jQclqocoyuJ/ulSZEgEkaoAQAAAAD+////Ak/cDgAAAAAAIlEgqxShDO8ifAouGyRHTFxWnTjpY69Cssr3IoNQvMYOKG/OVgAAAAAAACJRIGnlvMwBz4Ylb6xLTe5g4ZeZCxmVH/XWG+CDlcPzzaoT8qoGAAABAStAQg8AAAAAACJRIFGGvSoLWt3hRAIwYa8KEyawiFTXoOCVWFxYtSofZuAsIRZ2b8YiEpzexWYGt8B5EqLM8BE4qxJY3pkiGw/8zOZGYxkAvh7sj1YAAIABAACAAAAAgAAAAAAEAAAAARcgdm/GIhKc3sVmBrfAeRKizPAROKsSWN6ZIhsP/MzmRmMAAQUge7cvJMsJmR56NzObGOGkm8vNqaAIJdnBXLZD2PvrinIhB3u3LyTLCZkeejczmxjhpJvLzamgCCXZwVy2Q9j764pyGQC+HuyPVgAAgAEAAIAAAACAAQAAAAYAAAAAAQUgtIFPrI2EW/+PJiAmYdmux88p0KgeAxDFLMoeQoS66hIhB7SBT6yNhFv/jyYgJmHZrsfPKdCoHgMQxSzKHkKEuuoSGQC+HuyPVgAAgAEAAIAAAACAAAAAAAIAAAAA
//                """
//                return try! TxBuilderResult(
//                    psbt: .init(psbtBase64: pb64),
//                    transactionDetails: mockTransactionDetail
//                )
//            },
//            getBackupInfo: {
//                BackupInfo(
//                    mnemonic: "mnemonic",
//                    descriptor: "descriptor",
//                    changeDescriptor: "changeDescriptor"
//                )
//            }
//        )
//        static let mockZero = Self(
//            loadWallet: {},
//            deleteWallet: {},
//            createWallet: { _ in },
//            getBalance: { mockBalanceZero },
//            getTransactions: { mockTransactionDetailsZero },
//            sync: {},
//            getAddress: { "tb1pd8jmenqpe7rz2mavfdx7uc8pj7vskxv4rl6avxlqsw2u8u7d4gfs97durt" },
//            send: { _, _, _ in },
//            buildTransaction: { _, _, _ in
//                try! TxBuilderResult(
//                    psbt: .init(psbtBase64: "psbtBase64"),
//                    transactionDetails: mockTransactionDetail
//                )
//            },
//            getBackupInfo: {
//                BackupInfo(
//                    mnemonic: "mnemonic",
//                    descriptor: "descriptor",
//                    changeDescriptor: "changeDescriptor"
//                )
//            }
//        )
//    }
// #endif
