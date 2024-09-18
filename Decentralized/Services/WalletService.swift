//
//  BDKService.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/24.
//

import BitcoinDevKit
import Foundation
import Observation
import OSLog

enum WalletError: Error {
    case walletNotFound
    case storeNotFound
    case signError
    case blockchainConfigNotFound
    case noOutput
}

enum WalletMode: String, Codable, CaseIterable {
    case xverse
    case peek
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
            try esploraClient.sync(syncRequest: syncRequest, parallelRequests: 10)
        case .electrum(let electrumClient):
            try electrumClient.sync(syncRequest: syncRequest, batchSize: 10, fetchPrevTxouts: true)
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

class WalletSyncScriptInspector: SyncScriptInspector {
    private let updateProgress: (UInt64, UInt64) -> Void
    private var inspectedCount: UInt64 = 0
    private var totalCount: UInt64 = 0

    init(updateProgress: @escaping (UInt64, UInt64) -> Void) {
        self.updateProgress = updateProgress
    }

    func inspect(script: Script, total: UInt64) {
        self.totalCount = total
        self.inspectedCount += 1
        self.updateProgress(self.inspectedCount, self.totalCount)
    }
}

class WalletService {
    private var network: Networks

    private var payWallet: Wallet?
    private var payConn: Connection?
    private var payAddress: Address?

    private var ordiWallet: Wallet?
    private var ordiConn: Connection?
    private var ordiAddress: Address?

    private let syncClient: SyncClient

    private let logger: Logger = AppLogger(cat: "WalletService")

    init(
        network: Networks,
        syncClient: SyncClient
    ) {
        self.network = network
        self.syncClient = syncClient
    }

    func nextPayAddress() throws -> AddressInfo {
        guard let wallet = self.payWallet else {
            throw WalletError.walletNotFound
        }

        return wallet.revealNextAddress(keychain: .external)
    }

    func getPayAddress() -> Address {
        return self.payAddress!
    }

    func getOrdiAddress() -> Address {
        return self.ordiAddress!
    }

    func getBalance() throws -> Balance {
        guard let wallet = self.payWallet else {
            throw WalletError.walletNotFound
        }
        return wallet.balance()
    }

    func getTransactions() throws -> [CanonicalTx] {
        guard let wallet = self.payWallet else {
            throw WalletError.walletNotFound
        }
        let transactions = wallet.transactions()
        return transactions
    }

    func getUtxos() throws -> [LocalOutput] {
        guard let wallet = self.payWallet else {
            throw WalletError.walletNotFound
        }

        return wallet.listUnspent()
    }

    func getOutputs() throws -> [LocalOutput] {
        guard let wallet = self.payWallet else {
            throw WalletError.walletNotFound
        }

        return wallet.listOutput()
    }

    func getTxOut(op: OutPoint) throws -> TxOut? {
        guard let wallet = self.payWallet else {
            throw WalletError.walletNotFound
        }
        return wallet.getTxout(outpoint: op)
    }

    private func createDescriptor(words: String, mode: WalletMode) throws -> (Descriptor, Descriptor) {
        let mnemonic = try Mnemonic.fromString(mnemonic: words)

        let paySecretKey = DescriptorSecretKey(
            network: network.toBdkNetwork(),
            mnemonic: mnemonic,
            password: nil
        )

        let payDescriptor = switch mode {
        case .xverse:
            Descriptor.newBip49(
                secretKey: paySecretKey,
                keychain: .external,
                network: self.network.toBdkNetwork()
            )
        case .peek:
            Descriptor.newBip86(
                secretKey: paySecretKey,
                keychain: .external,
                network: self.network.toBdkNetwork()
            )
        }

        let ordiDescriptor = Descriptor.newBip86(
            secretKey: paySecretKey,
            keychain: .external,
            network: self.network.toBdkNetwork()
        )

        return (payDescriptor, ordiDescriptor)
    }

    func createWallet(words: String?, mode: WalletMode) throws {
        try self.deleteWallet()

        var words12: String

        if let words = words, !words.isEmpty {
            words12 = words
        } else {
            let mnemonic = Mnemonic(wordCount: WordCount.words12)
            words12 = mnemonic.description
        }

        let (payDescriptor, ordiDescriptor) = try createDescriptor(words: words12, mode: mode)

        let documentsDirectoryURL = FileManager.default.getDocumentsDirectoryPath()
        let payWalletDataDirectoryURL = documentsDirectoryURL.appendingPathComponent("pay_\(self.network.rawValue).sqlite")
        let payPersistenceBackendPath = payWalletDataDirectoryURL.path
        self.logger.info("PayDB URl:\(payPersistenceBackendPath)")

        let payDb = try Connection(path: payPersistenceBackendPath)

        self.logger.info("Read OK")

        let payWallet = try Wallet.createSingle(
            descriptor: payDescriptor,
            network: self.network.toCustomNetwork(),
            connection: payDb
        )

        let ordiWalletDataDirectoryURL = documentsDirectoryURL.appendingPathComponent("ordi_\(self.network.rawValue).sqlite")
        let ordiPersistenceBackendPath = ordiWalletDataDirectoryURL.path

        let ordiDb = try! Connection(path: ordiPersistenceBackendPath)

        self.logger.info("OrdiDB URl:\(ordiPersistenceBackendPath)")

        let ordiWallet = try Wallet.createSingle(
            descriptor: ordiDescriptor,
            network: self.network.toCustomNetwork(),
            connection: ordiDb
        )

        self.logger.info("Peek Address")
        let payAddress = payWallet.peekAddress(keychain: .external, index: 0).address
        _ = payWallet.revealAddressesTo(keychain: .external, index: 0)
        var ordiAddress = ordiWallet.peekAddress(keychain: .external, index: 0).address
        _ = ordiWallet.revealAddressesTo(keychain: .external, index: 0)
        if mode == .peek {
            ordiAddress = ordiWallet.peekAddress(keychain: .external, index: 1).address
            _ = ordiWallet.revealAddressesTo(keychain: .external, index: 1)
        }

        _ = try payWallet.persist(connection: payDb)

        _ = try ordiWallet.persist(connection: ordiDb)

        self.payWallet = payWallet
        self.ordiWallet = ordiWallet
        self.payAddress = payAddress
        self.ordiAddress = ordiAddress
        self.payConn = payDb
        self.ordiConn = ordiDb

        let backupInfo = BackupInfo(
            mnemonic: words12,
            mode: mode
        )
        try KeyChainService.saveBackupInfo(backupInfo)
    }

    private func loadWallet(mode: WalletMode, payDescriptor: Descriptor, ordiDescriptor: Descriptor) throws {
        let documentsDirectoryURL = FileManager.default.getDocumentsDirectoryPath()

        let payWalletDataDirectoryURL = documentsDirectoryURL.appendingPathComponent("pay_\(self.network.rawValue).sqlite")
        let payPersistenceBackendPath = payWalletDataDirectoryURL.path

        let db = try Connection(path: payPersistenceBackendPath)

        let payWallet = try Wallet.load(
            descriptor: payDescriptor,
            changeDescriptor: nil,
            connection: db
        )

        let ordiWalletDataDirectoryURL = documentsDirectoryURL.appendingPathComponent("ordi_\(self.network.rawValue).sqlite")
        let ordiPersistenceBackendPath = ordiWalletDataDirectoryURL.path
        let ordiDb = try Connection(path: ordiPersistenceBackendPath)

        let ordiWallet = try Wallet.load(
            descriptor: ordiDescriptor,
            changeDescriptor: nil,
            connection: ordiDb
        )

        let payAddr = payWallet.peekAddress(keychain: .external, index: 0).address
        var ordiAddr = ordiWallet.peekAddress(keychain: .external, index: 0).address
        if mode == .peek {
            ordiAddr = ordiWallet.peekAddress(keychain: .external, index: 1).address
        }

        self.payWallet = payWallet
        self.ordiWallet = ordiWallet
        self.payAddress = payAddr
        self.ordiAddress = ordiAddr
        self.payConn = db
        self.ordiConn = ordiDb
    }

    func loadWalletFromBackup() throws {
        let backupInfo = try KeyChainService.getBackupInfo()

        self.logger.info("loadWalletFromBackup: \(self.network.rawValue)")

        if !FileManager.default.fileExists(atPath: FileManager.default.getDocumentsDirectoryPath().appendingPathComponent("pay_\(self.network.rawValue).sqlite").path) {
            self.logger.info("Load Create: \(self.network.rawValue)")
            try self.createWallet(words: backupInfo.mnemonic, mode: backupInfo.mode)
            return
        }

        let (payDescriptor, ordiDescriptor) = try createDescriptor(words: backupInfo.mnemonic, mode: backupInfo.mode)

        try self.loadWallet(mode: backupInfo.mode, payDescriptor: payDescriptor, ordiDescriptor: ordiDescriptor)
    }

    func deleteWallet() throws {
//        if let bundleID = Bundle.main.bundleIdentifier {
//            UserDefaults.standard.removePersistentDomain(forName: bundleID)
//        }
        try KeyChainService.deleteBackupInfo()
        try FileManager.default.deleteAllContentsInDocumentsDirectory()
    }

    func buildTx(_ tx: TxBuilder) throws -> (BitcoinDevKit.Transaction, Psbt) {
        guard let wallet = self.payWallet else { throw WalletError.walletNotFound }

        let psbt = try tx.finish(wallet: wallet)
        return try (psbt.extractTx(), psbt)
    }

    func buildAndSignTx(_ tx: TxBuilder) throws -> (BitcoinDevKit.Transaction, Psbt) {
        guard let wallet = self.payWallet else { throw WalletError.walletNotFound }

        let psbt = try tx.finish(wallet: wallet)
        let ok = try wallet.sign(psbt: psbt)
        if !ok {
            print("SIgn error")
        }

        return try (psbt.extractTx(), psbt)
    }

    func buildTransaction(address: String, amount: UInt64, feeRate: UInt64) throws
        -> Psbt
    {
        guard let wallet = self.payWallet else { throw WalletError.walletNotFound }
        let script = try Address(address: address, network: self.network.toBdkNetwork())
            .scriptPubkey()
        let txBuilder = try TxBuilder()
            .addRecipient(
                script: script,
                amount: Amount.fromSat(fromSat: amount)
            )
            .feeRate(feeRate: FeeRate.fromSatPerVb(satPerVb: feeRate))
            .drainTo(script: self.payAddress!.scriptPubkey())
            .finish(wallet: wallet)
        return txBuilder
    }

    func signAndBroadcast(psbt: Psbt) throws {
        guard let wallet = self.payWallet else { throw WalletError.walletNotFound }
        let isSigned = try wallet.sign(psbt: psbt)
        if isSigned {
            let transaction = try psbt.extractTx()
            let client = self.syncClient
            try client.broadcast(transaction)
        } else {
            throw WalletError.walletNotFound
        }
    }

    func sign(_ psbt: Psbt) throws -> Psbt {
        guard let wallet = self.payWallet else { throw WalletError.walletNotFound }

        let ok = try wallet.sign(psbt: psbt)
        if !ok {
            throw WalletError.signError
        }
        return psbt
    }

    func inspector(inspectedCount: UInt64, total: UInt64) {
//        print(inspectedCount, total)
    }

    func sync() async throws {
        guard let wallet = self.payWallet else { throw WalletError.walletNotFound }
        guard let payConn = self.payConn else { throw WalletError.walletNotFound }

        let syncRequest = try wallet.startSyncWithRevealedSpks().inspectSpks(inspector: WalletSyncScriptInspector(updateProgress: self.inspector)).build()

        self.logger.info("Syning")

        let update = try syncClient.sync(syncRequest)

        self.logger.info("Update")
        try wallet.applyUpdate(update: update)
        self.logger.info("Persist")
        _ = try wallet.persist(connection: payConn)

        // TODO: Do i need to do this next step of setting wallet to wallet again?
        // prob not
        self.payWallet = wallet
    }

    func calculateFee(_ tx: BitcoinDevKit.Transaction) -> UInt64 {
        do {
            let fee = try self.payWallet!.calculateFee(tx: tx)
            return fee.toSat()
        } catch {
            return 0
        }
    }

    func calculateFeeRate(_ tx: BitcoinDevKit.Transaction) -> UInt64 {
        do {
            let feeRate = try self.payWallet!.calculateFeeRate(tx: tx)
            return feeRate.toSatPerVbCeil()
        } catch {
            return 0
        }
    }

    func sentAndReceived(_ tx: BitcoinDevKit.Transaction) -> SentAndReceivedValues {
        self.payWallet!.sentAndReceived(tx: tx)
    }

    func broadcast(_ tx: BitcoinDevKit.Transaction) throws -> String {
        let txid = try self.syncClient.broadcast(tx)

        self.payWallet!.applyUnconfirmedTxs(txAndLastSeens: [TransactionAndLastSeen(tx: tx, lastSeen: UInt64(Date().timeIntervalSince1970))])
//        self.logger.info("Insert Tx ")
        let _ = try self.payWallet!.persist(connection: self.payConn!)

        return txid
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
