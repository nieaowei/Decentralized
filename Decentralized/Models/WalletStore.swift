//
//  Wallet.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/2.
//

import BitcoinDevKit
import Foundation
import SwiftUI

struct WalletTransaction: Identifiable {
    private let walletService: WalletService
    
    var inner: CanonicalTx
    
    init(walletService: WalletService, inner: CanonicalTx) {
        self.walletService = walletService
        self.inner = inner
    }
    
    var id: String {
        txid
    }
    
    var txid: String {
        inner.transaction.computeTxid()
    }

    var inputs: [TxIn] {
        inner.transaction.input()
    }
    
    var isLockTimeEnabled: Bool {
        inner.transaction.isLockTimeEnabled()
    }
    
    var isExplicitlyRbf: Bool {
        inner.transaction.isExplicitlyRbf()
    }
    
    var lockTime: UInt32 {
        inner.transaction.lockTime()
    }
    
    var outputs: [TxOut] {
        inner.transaction.output()
    }
    
    var version: Int32 {
        inner.transaction.version()
    }

    var totalSize: UInt64 {
        inner.transaction.totalSize()
    }
    
    var vsize: UInt64 {
        inner.transaction.vsize()
    }
    
    var weight: UInt64 {
        inner.transaction.weight()
    }
    
    var timestamp: UInt64 {
        switch inner.chainPosition {
        case .confirmed(let ts): ts.confirmationTime
        case .unconfirmed: UInt64(Date().timeIntervalSince1970)
        }
    }

    var date: Date {
        return Calendar.current.startOfDay(for: inner.timestamp.toDate())
    }

    var isComfirmed: Bool {
        switch inner.chainPosition {
        case .confirmed: true
        case .unconfirmed: false
        }
    }
    
    var changeAmount: Double {
        let sentAndRecv = try! walletService.sentAndReceived(inner.transaction)
        let sent = sentAndRecv.sent
        let recv = sentAndRecv.received
        let (plus, change) = if sent.toSat() > recv.toSat() {
            (false, sent.toSat() - recv.toSat())
        } else {
            (true, recv.toSat() - sent.toSat())
        }
        let changeBtc = Amount.fromSat(fromSat: change).toBtc()

        return plus ? changeBtc : -changeBtc
    }
}

@Observable
class WalletStore {
    enum SyncStatus: Equatable {
        case error(String)
        case notStarted
        case syncing
        case synced
    }
    
    private let wallet: WalletService
    
    var balance: Amount = .fromSat(fromSat: 0)
    var payAddress: Address?
    var ordiAddress: Address?
    var transactions: [WalletTransaction] = []
    var utxos: [LocalOutput] = []
    
    var syncStatus: SyncStatus = .notStarted
    
    init(wallet: WalletService) {
        self.wallet = wallet
        self.load()
    }
    
    func load() {
        do {
            try wallet.loadWalletFromBackup()
            balance = try wallet.getBalance().total
            payAddress =  wallet.getPayAddress()
            ordiAddress =  wallet.getOrdiAddress()
            transactions = try wallet.getTransactions().map { ctx in
                WalletTransaction(walletService: wallet, inner: ctx)
            }
            utxos = try wallet.getUtxos()
        } catch {}
    }
    
    func sync() async throws {
        syncStatus = .syncing
        try await wallet.sync()
        syncStatus = .synced
    }
    
    func create(words: String, mode: WalletMode) throws {
        try wallet.createWallet(words: words, mode: mode)
    }
    
    func delete() throws {
        try wallet.deleteWallet()
    }
}
