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
    case blockchainConfigNotFound
    case noOutput
}

enum WalletMode: String, Codable, CaseIterable {
    case xverse
    case peek
}

private class BDKService {
    static var shared: BDKService = .init()

    private var balance: Balance?
    var network: Network
    private var payWallet: Wallet?
    private var payDB: SqliteStore?
    private var payAddress: Address?

    private var ordiWallet: Wallet?
    private var ordiDB: SqliteStore?
    private var ordiAddress: Address?
    private let keyService: KeyClient
    private let esploraClient: EsploraClient
    private let electurmClient: ElectrumClient

    init(
        keyService: KeyClient = .live
    ) {
        let storedNetworkString = try! keyService.getNetwork() ?? Network.bitcoin.description
        let storedEsploraURL =
            try! keyService.getEsploraURL()
                ?? Constants.Config.EsploraServerURLNetwork.Bitcoin.mempoolspace

        self.network = Network(stringValue: storedNetworkString) ?? .bitcoin
        self.keyService = keyService

        self.esploraClient = EsploraClient(url: storedEsploraURL)
        self.electurmClient = try! ElectrumClient(url: "ssl://electrum.blockstream.info:50002")
    }

    func nextPayAddress() throws -> AddressInfo {
        guard let wallet = self.payWallet else {
            throw WalletError.walletNotFound
        }

        return try wallet.revealNextAddress(keychain: .external)
    }

    func getPayAddress() -> Address {
        return self.payAddress!
    }

    func nextOrdiAddress() throws -> AddressInfo {
        guard let wallet = self.ordiWallet else {
            throw WalletError.walletNotFound
        }
        return try wallet.revealNextAddress(keychain: .external)
    }

    func getOrdiAddress() -> Address {
        return self.ordiAddress!
    }

    func getBalance() throws -> Balance {
        guard let wallet = self.payWallet else { throw WalletError.walletNotFound }
        let balance = wallet.balance()
        return balance
    }

    func transactions() throws -> [CanonicalTx] {
        guard let wallet = self.payWallet else {
            throw WalletError.walletNotFound
        }
        let transactions = wallet.transactions()
        return transactions
    }

    func utxos() throws -> [LocalOutput] {
        guard let wallet = self.payWallet else {
            throw WalletError.walletNotFound
        }

        return wallet.listUnspent()
    }

    func outputs() throws -> [LocalOutput] {
        guard let wallet = self.payWallet else {
            throw WalletError.walletNotFound
        }

        return wallet.listOutput()
    }

    func createWallet(words: String?, mode: WalletMode) throws {
        let baseUrl =
            try! self.keyService.getEsploraURL()
                ?? Constants.Config.EsploraServerURLNetwork.Bitcoin.mempoolspace

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

        let payDb = try! SqliteStore(path: payPersistenceBackendPath)
        let paySet = try! payDb.read()

        logger.info("Read OK")

        let payWallet = try Wallet.newOrLoad(
            descriptor: payDescriptor,
            changeDescriptor: payChangeDescriptor,
            changeSet: paySet,
            network: self.network
        )

        let ordiWalletDataDirectoryURL = documentsDirectoryURL.appendingPathComponent("ordi_wallet_data.sqlite")
        let ordiPersistenceBackendPath = ordiWalletDataDirectoryURL.path

        let ordiDb = try! SqliteStore(path: ordiPersistenceBackendPath)
        let ordiSet = try! ordiDb.read()

        logger.info("OrdiDB URl:\(ordiPersistenceBackendPath)")

        let ordiWallet = try Wallet.newOrLoad(
            descriptor: ordiDescriptor,
            changeDescriptor: ordiChangeDescriptor,
            changeSet: ordiSet,
            network: self.network
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

        if let change = payWallet.takeStaged() {
            try payDb.write(changeSet: change)
        }

        if let change = ordiWallet.takeStaged() {
            try ordiDb.write(changeSet: change)
        }

        self.payWallet = payWallet
        self.ordiWallet = ordiWallet
        self.payAddress = payAddress
        self.ordiAddress = ordiAddress
        self.payDB = payDb
        self.ordiDB = ordiDb

        // store
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
        try self.keyService.saveNetwork(self.network.description)
        try self.keyService.saveEsploraURL(baseUrl)
    }

    private func loadWallet(payDescriptor: Descriptor, payChangeDesc: Descriptor, payAddr: Address, ordiDescriptor: Descriptor, ordiChangeDesc: Descriptor, ordiAddr: Address) throws {
        let documentsDirectoryURL = FileManager.default.getDocumentsDirectoryPath()

        let payWalletDataDirectoryURL = documentsDirectoryURL.appendingPathComponent("pay_wallet_data.sqlite")
        let payPersistenceBackendPath = payWalletDataDirectoryURL.path

        let db = try SqliteStore(path: payPersistenceBackendPath)
        let paySet = try! db.read()

        let payWallet = try Wallet.newOrLoad(
            descriptor: payDescriptor,
            changeDescriptor: payChangeDesc,
            changeSet: paySet,
            network: self.network
        )

        let ordiWalletDataDirectoryURL = documentsDirectoryURL.appendingPathComponent("ordi_wallet_data.sqlite")
        let ordiPersistenceBackendPath = ordiWalletDataDirectoryURL.path
        let ordiDb = try SqliteStore(path: ordiPersistenceBackendPath)
        let ordiSet = try! ordiDb.read()

        let ordiWallet = try Wallet.newOrLoad(
            descriptor: ordiDescriptor,
            changeDescriptor: ordiChangeDesc,
            changeSet: ordiSet,
            network: self.network
        )
        self.payWallet = payWallet
        self.ordiWallet = ordiWallet
        self.payAddress = payAddr
        self.ordiAddress = ordiAddr
        self.payDB = db
        self.ordiDB = ordiDb
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
        try self.keyService.deleteEsplora()
        try self.keyService.deleteNetwork()
        try FileManager.default.deleteAllContentsInDocumentsDirectory()
    }

    func getBackupInfo() throws -> BackupInfo {
        let backupInfo = try keyService.getBackupInfo()
        return backupInfo
    }

    func send(
        address: String,
        amount: UInt64,
        feeRate: UInt64
    ) async throws {
        let psbt = try buildTransaction(
            address: address,
            amount: amount,
            feeRate: feeRate
        )
        try signAndBroadcast(psbt: psbt)
    }

    func buildTransaction(address: String, amount: UInt64, feeRate: UInt64) throws
        -> Psbt
    {
        guard let wallet = self.payWallet else { throw WalletError.walletNotFound }
        let script = try Address(address: address, network: self.network)
            .scriptPubkey()
        let txBuilder = try TxBuilder()
            .addRecipient(
                script: script,
                amount: Amount.fromSat(fromSat: amount) // amount: amount
            )
            .feeRate(feeRate: FeeRate.fromSatPerVb(satPerVb: feeRate))
            .finish(wallet: wallet)

        return txBuilder
    }

    func getChangeAmount(_ tx: TxBuilder) throws -> Amount {
        guard let wallet = self.payWallet else { throw WalletError.walletNotFound }
        let psbt = try tx.finish(wallet: wallet)
        let transaction = try psbt.extractTx()
        guard let o = transaction.output().last else {
            throw WalletError.noOutput
        }
        return Amount.fromSat(fromSat: o.value)
    }

    func buildTxAndSign(_ tx: TxBuilder) throws {
        guard let wallet = self.payWallet else { throw WalletError.walletNotFound }
        let psbt = try tx.finish(wallet: wallet)
        print(psbt.serializeHex())

        let transaction = try psbt.extractTx()
        
//        print(transaction.serialize().map { String(format: "%02x", $0) }.joined())
    }

    private func signAndBroadcast(psbt: Psbt) throws {
        guard let wallet = self.payWallet else { throw WalletError.walletNotFound }
        _ = try wallet.sign(psbt: psbt)
        let transaction = try psbt.extractTx()
        print(transaction)
//        let client = self.esploraClient
//        try client.broadcast(transaction: transaction)
    }

    func sync() async throws {
        guard let wallet = self.payWallet else { throw WalletError.walletNotFound }
        let esploraClient = self.esploraClient
        let syncRequest = wallet.startSyncWithRevealedSpks()
//        let update = try electurmClient.sync(syncRequest: syncRequest, batchSize: 10, fetchPrevTxouts: true)
        let update = try esploraClient.sync(
            syncRequest: syncRequest,
            parallelRequests: UInt64(5)
        )
        try wallet.applyUpdate(update: update)
        if let change = self.payWallet?.takeStaged() {
            try self.payDB?.write(changeSet: change)
        }
        // TODO: Do i need to do this next step of setting wallet to wallet again?
        // prob not
        self.payWallet = wallet
    }

    func fullScan() async throws {
        guard let wallet = self.payWallet else { throw WalletError.walletNotFound }
        let esploraClient = esploraClient
        let fullScanRequest = wallet.startFullScan()
        let update = try esploraClient.fullScan(
            fullScanRequest: fullScanRequest,
            stopGap: UInt64(150), // should we default value this for folks?
            parallelRequests: UInt64(5) // should we default value this for folks?
        )
        _ = try wallet.applyUpdate(update: update)
        // TODO: Do i need to do this next step of setting wallet to wallet again?
        // prob not
        self.payWallet = wallet
    }

    func calculateFee(tx: Transaction) throws -> UInt64 {
        guard let wallet = self.payWallet else {
            throw WalletError.walletNotFound
        }
        let fee = try wallet.calculateFee(tx: tx)
        return fee.toSat()
    }

    func calculateFeeRate(tx: Transaction) throws -> UInt64 {
        guard let wallet = self.payWallet else {
            throw WalletError.walletNotFound
        }
        let feeRate = try wallet.calculateFeeRate(tx: tx)
        return feeRate.toSatPerVbCeil() // TODO: is this the right method to use on feerate?
    }

    func sentAndReceived(tx: Transaction) throws -> SentAndReceivedValues {
        guard let wallet = self.payWallet else {
            throw WalletError.walletNotFound
        }
        let values = wallet.sentAndReceived(tx: tx)
        return values
    }
}

struct BDKClient {
    let loadWallet: () throws -> Void
    let deleteWallet: () throws -> Void
    let createWallet: (String?, WalletMode) throws -> Void
    let getBalance: () throws -> Balance
    let transactions: () throws -> [CanonicalTx]
    let utxos: () throws -> [LocalOutput]
    let outputs: () throws -> [LocalOutput]
    let sync: () async throws -> Void
    let fullScan: () async throws -> Void
    let getPayAddress: () throws -> Address
    let getOrdiAddress: () throws -> Address
    let send: (String, UInt64, UInt64) throws -> Void
    let calculateFee: (Transaction) throws -> UInt64
    let calculateFeeRate: (Transaction) throws -> UInt64
    let sentAndReceived: (Transaction) throws -> SentAndReceivedValues
    let buildTransaction: (String, UInt64, UInt64) throws -> Psbt
    let getBackupInfo: () throws -> BackupInfo
    let buildTxAndSign: (_ tx: TxBuilder) throws -> Void
    let getChangeAmount: (_ tx: TxBuilder) throws -> Amount
}

extension BDKClient {
    static let live = Self(
        loadWallet: { try BDKService.shared.loadWalletFromBackup() },
        deleteWallet: { try BDKService.shared.deleteWallet() },
        createWallet: { words, mode in try BDKService.shared.createWallet(words: words, mode: mode) },
        getBalance: { try BDKService.shared.getBalance() },
        transactions: { try BDKService.shared.transactions() },
        utxos: { try BDKService.shared.utxos() },
        outputs: { try BDKService.shared.outputs() },
        sync: { try await BDKService.shared.sync() },
        fullScan: { try await BDKService.shared.fullScan() },
        getPayAddress: { BDKService.shared.getPayAddress() },
        getOrdiAddress: { BDKService.shared.getOrdiAddress() },

        send: { address, amount, feeRate in
            Task {
                try await BDKService.shared.send(address: address, amount: amount, feeRate: feeRate)
            }
        },
        calculateFee: { tx in try BDKService.shared.calculateFee(tx: tx) },
        calculateFeeRate: { tx in try BDKService.shared.calculateFeeRate(tx: tx) },
        sentAndReceived: { tx in try BDKService.shared.sentAndReceived(tx: tx) },
        buildTransaction: { address, amount, feeRate in
            try BDKService.shared.buildTransaction(
                address: address,
                amount: amount,
                feeRate: feeRate
            )
        },
        getBackupInfo: { try BDKService.shared.getBackupInfo() },
        buildTxAndSign: { tx in try BDKService.shared.buildTxAndSign(tx) },
        getChangeAmount: { tx in try BDKService.shared.getChangeAmount(tx) }
    )
}

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
