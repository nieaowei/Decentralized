//
//  BDKService.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/24.
//

import BitcoinDevKit
import Foundation

enum WalletError: Error {
    case walletNotFound
    case storeNotFound
    case blockchainConfigNotFound
    case noOutput
}

enum WalletMode: String, Codable, CaseIterable {
    case xverse
    case peek
}

enum SyncClient {
    case esplora(EsploraClient)
    case electrum(ElectrumClient)

    func broadcast(_ tx: Transaction) throws -> String {
        return switch self {
        case .esplora(let esploraClient):
            try {
                try esploraClient.broadcast(transaction: tx)
                return ""
            }()
        case .electrum(let electrumClient):
            try electrumClient.broadcast(transaction: tx)
        }
    }

    func sync(syncRequest: SyncRequest) throws -> Update {
        return switch self {
        case .esplora(let esploraClient):
            try esploraClient.sync(syncRequest: syncRequest, parallelRequests: 10)
        case .electrum(let electrumClient):
            try electrumClient.sync(syncRequest: syncRequest, batchSize: 10, fetchPrevTxouts: true)
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
    private let keyService: KeyService = .shared

    private var network: Network

    private var payWallet: Wallet?
    private var payConn: Connection?
    private var payAddress: Address?

    private var ordiWallet: Wallet?
    private var ordiConn: Connection?
    private var ordiAddress: Address?

    private let syncClient: SyncClient

    init(
        network: Network,
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

    func createWallet(words: String?, mode: WalletMode) throws {
        var words12: String

        if let words = words, !words.isEmpty {
            words12 = words
        } else {
            let mnemonic = Mnemonic(wordCount: WordCount.words12)
            words12 = mnemonic.description
        }
        let mnemonic = try Mnemonic.fromString(mnemonic: words12)

        let paySecretKey = DescriptorSecretKey(
            network: network,
            mnemonic: mnemonic,
            password: nil
        )

        let payDescriptor = switch mode {
        case .xverse:
            Descriptor.newBip49(
                secretKey: paySecretKey,
                keychain: .external,
                network: self.network
            )
        case .peek:
            Descriptor.newBip86(
                secretKey: paySecretKey,
                keychain: .external,
                network: self.network
            )
        }

        let payChangeDescriptor = switch mode {
        case .xverse:
            Descriptor.newBip49(
                secretKey: paySecretKey,
                keychain: .internal,
                network: self.network
            )
        case .peek:
            Descriptor.newBip86(
                secretKey: paySecretKey,
                keychain: .internal,
                network: self.network
            )
        }

        let ordiDescriptor = Descriptor.newBip86(
            secretKey: paySecretKey,
            keychain: .external,
            network: self.network
        )
        let ordiChangeDescriptor = Descriptor.newBip86(
            secretKey: paySecretKey,
            keychain: .internal,
            network: self.network
        )

        let documentsDirectoryURL = FileManager.default.getDocumentsDirectoryPath()
        let payWalletDataDirectoryURL = documentsDirectoryURL.appendingPathComponent("pay_wallet_data.sqlite")
        let payPersistenceBackendPath = payWalletDataDirectoryURL.path
        logger.info("PayDB URl:\(payPersistenceBackendPath)")

        let payDb = try Connection(path: payPersistenceBackendPath)

        logger.info("Read OK")

        let payWallet = try Wallet(
            descriptor: payDescriptor,
            changeDescriptor: payChangeDescriptor,
            network: self.network,
            connection: payDb
        )

        let ordiWalletDataDirectoryURL = documentsDirectoryURL.appendingPathComponent("ordi_wallet_data.sqlite")
        let ordiPersistenceBackendPath = ordiWalletDataDirectoryURL.path

        let ordiDb = try! Connection(path: ordiPersistenceBackendPath)

        logger.info("OrdiDB URl:\(ordiPersistenceBackendPath)")

        let ordiWallet = try Wallet(
            descriptor: ordiDescriptor,
            changeDescriptor: ordiChangeDescriptor,
            network: self.network,
            connection: ordiDb
        )

        logger.info("Peek Address")
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
            mnemonic: mnemonic.description,
            payDescriptor: payDescriptor.description,
            payChangeDescriptor: payChangeDescriptor.description,
            payAddress: payAddress.description,
            ordiDescriptor: ordiDescriptor.description,
            ordiChangeDescriptor: ordiChangeDescriptor.description,
            ordiAddress: ordiAddress.description,
            mode: mode
        )

        try self.keyService.saveBackupInfo(backupInfo)
    }

    private func loadWallet(payDescriptor: Descriptor, payChangeDesc: Descriptor, payAddr: Address, ordiDescriptor: Descriptor, ordiChangeDesc: Descriptor, ordiAddr: Address) throws {
        let documentsDirectoryURL = FileManager.default.getDocumentsDirectoryPath()

        let payWalletDataDirectoryURL = documentsDirectoryURL.appendingPathComponent("pay_wallet_data.sqlite")
        let payPersistenceBackendPath = payWalletDataDirectoryURL.path

        let db = try Connection(path: payPersistenceBackendPath)

        let payWallet = try Wallet.load(
            descriptor: payDescriptor,
            changeDescriptor: payChangeDesc,
            connection: db
        )

        let ordiWalletDataDirectoryURL = documentsDirectoryURL.appendingPathComponent("ordi_wallet_data.sqlite")
        let ordiPersistenceBackendPath = ordiWalletDataDirectoryURL.path
        let ordiDb = try Connection(path: ordiPersistenceBackendPath)

        let ordiWallet = try Wallet.load(
            descriptor: ordiDescriptor,
            changeDescriptor: ordiChangeDesc,
            connection: ordiDb
        )
        self.payWallet = payWallet
        self.ordiWallet = ordiWallet
        self.payAddress = payAddr
        self.ordiAddress = ordiAddr
        self.payConn = db
        self.ordiConn = ordiDb
    }

    func loadWalletFromBackup() throws {
        let backupInfo = try keyService.getBackupInfo()
        let payDescriptor = try Descriptor(descriptor: backupInfo.payDescriptor, network: self.network)
        let payChangeDescriptor = try Descriptor(descriptor: backupInfo.payChangeDescriptor, network: self.network)

        let ordiDescriptor = try Descriptor(descriptor: backupInfo.ordiDescriptor, network: self.network)
        let ordiChangeDescriptor = try Descriptor(descriptor: backupInfo.ordiChangeDescriptor, network: self.network)

        let payAddr = try Address(address: backupInfo.payAddress, network: self.network)
        let ordiAddr = try Address(address: backupInfo.ordiAddress, network: self.network)
        try self.loadWallet(payDescriptor: payDescriptor, payChangeDesc: payChangeDescriptor, payAddr: payAddr, ordiDescriptor: ordiDescriptor, ordiChangeDesc: ordiChangeDescriptor, ordiAddr: ordiAddr)
    }

    func deleteWallet() throws {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        try self.keyService.deleteBackupInfo()
        try FileManager.default.deleteAllContentsInDocumentsDirectory()
    }

    func buildTx(_ tx: TxBuilder) throws -> BitcoinDevKit.Transaction {
        guard let wallet = self.payWallet else { throw WalletError.walletNotFound }

        let psbt = try tx.finish(wallet: wallet)
        return try psbt.extractTx()
    }

    func sign(_ tx: TxBuilder) throws -> (Bool, Psbt) {
        guard let wallet = self.payWallet else { throw WalletError.walletNotFound }

        let psbt = try tx.finish(wallet: wallet)

        let ok = try wallet.sign(psbt: psbt)
        print(psbt.serializeHex())
        return (ok, psbt)
    }

    func inspector(inspectedCount: UInt64, total: UInt64) {
        print(inspectedCount, total)
    }

    func sync() async throws {
        guard let wallet = self.payWallet else { throw WalletError.walletNotFound }
        guard let payConn = self.payConn else { throw WalletError.walletNotFound }

        let syncRequest = try wallet.startSyncWithRevealedSpks().inspectSpks(inspector: WalletSyncScriptInspector(updateProgress: self.inspector)).build()

        let update = try syncClient.sync(syncRequest: syncRequest)

        try wallet.applyUpdate(update: update)

        _ = try wallet.persist(connection: payConn)

        // TODO: Do i need to do this next step of setting wallet to wallet again?
        // prob not
        self.payWallet = wallet
    }

    func calculateFee(_ tx: BitcoinDevKit.Transaction) throws -> UInt64 {
        guard let wallet = self.payWallet else {
            throw WalletError.walletNotFound
        }
        let fee = try wallet.calculateFee(tx: tx)
        return fee.toSat()
    }

    func calculateFeeRate(_ tx: BitcoinDevKit.Transaction) throws -> UInt64 {
        guard let wallet = self.payWallet else {
            throw WalletError.walletNotFound
        }
        let feeRate = try wallet.calculateFeeRate(tx: tx)
        return feeRate.toSatPerVbCeil() // TODO: is this the right method to use on feerate?
    }

    func sentAndReceived(_ tx: BitcoinDevKit.Transaction) throws -> SentAndReceivedValues {
        guard let wallet = self.payWallet else {
            throw WalletError.walletNotFound
        }
        let values = wallet.sentAndReceived(tx: tx)
        return values
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

