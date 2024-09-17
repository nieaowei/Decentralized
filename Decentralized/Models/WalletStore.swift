//
//  Wallet.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/2.
//

import BitcoinDevKit
import Foundation
import SwiftUI

struct WalletTransaction: Identifiable, Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func ==(l: Self, r: Self) -> Bool {
        return l.id == r.id
    }
    
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
        let sentAndRecv = walletService.sentAndReceived(inner.transaction)
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
    
    var fee: UInt64 {
        walletService.calculateFee(inner.transaction)
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
    
    let wallet: WalletService
    
    @MainActor
    var balance: Amount = .fromSat(fromSat: 0)
    @MainActor
    var payAddress: Address?
    @MainActor
    var ordiAddress: Address?

    @MainActor
    var transactions: [WalletTransaction] = []
    
    @MainActor
    var utxos: [LocalOutput] = []
    
    @MainActor
    var syncStatus: SyncStatus = .notStarted
    
    init(wallet: WalletService) {
        self.wallet = wallet
        DispatchQueue.main.async {
            try! wallet.loadWalletFromBackup()

            self.load()
        }
    }
    
    func getTxOut(_ op: OutPoint) throws -> TxOut? {
        return try wallet.getTxOut(op: op)
    }
    
    @MainActor
    func load() {
        do {
            balance = try wallet.getBalance().total
            payAddress = wallet.getPayAddress()
            ordiAddress = wallet.getOrdiAddress()
            transactions = try wallet.getTransactions().map { ctx in
                WalletTransaction(walletService: wallet, inner: ctx)
            }
            utxos = try wallet.getUtxos()
        } catch {
            print(error)
        }
    }
    
    @MainActor
    func updateStatus(_ status: SyncStatus) {
        syncStatus = status
    }
    
    func sync() async throws {
        if await self.syncStatus != .syncing{
            do {
                await updateStatus(.syncing)
                try await wallet.sync()
                await updateStatus(.synced)
                await load()
            } catch {
                await updateStatus(.error(error.localizedDescription))
                throw error
            }
        }
    }
    
    func create(words: String, mode: WalletMode) throws {
        try wallet.createWallet(words: words, mode: mode)
    }
    
    func delete() throws {
        try wallet.deleteWallet()
    }
    
    func buildTx(_ tx: TxBuilder) throws -> (BitcoinDevKit.Transaction, Psbt) {
        return try wallet.buildTx(tx)
    }
    
    func buildAndSignTx(_ tx: TxBuilder) throws -> (BitcoinDevKit.Transaction, Psbt) {
        return try wallet.buildAndSignTx(tx)
    }
    
    func sign(_ psbt: Psbt) throws -> Psbt {
        try wallet.sign(psbt)
    }
    
    func createWalletTx(tx: BitcoinDevKit.Transaction) -> WalletTransaction {
        WalletTransaction(walletService: wallet, inner: CanonicalTx(transaction: tx, chainPosition: ChainPosition.unconfirmed(timestamp: 0)))
    }
    
    func broadcast(_ tx: BitcoinDevKit.Transaction) throws -> String{
        try self.wallet.broadcast(tx)
    }
}
