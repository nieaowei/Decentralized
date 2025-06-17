//
//  Wallet.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/2.
//

import DecentralizedFFI
import Foundation
import SwiftUI

struct WalletTransaction: Identifiable, Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func ==(l: Self, r: Self) -> Bool {
        return l.id == r.id && l.inner.transaction == r.inner.transaction
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
    
    var canRBF: Bool {
        inputs.contains { txin in
            if let tx = walletService.getTxOut(op: txin.previousOutput), self.isExplicitlyRbf {
                return walletService.isMine(script: tx.scriptPubkey)
            }
            return false
        }
    }
    
    var canCPFP: Bool {
        outputs.contains { txout in
            walletService.isMine(script: txout.scriptPubkey)
        }
    }
    
    var isCPFP: Bool {
        inputs.contains { txin in
            if let txOut = walletService.getTxOut(op: txin.previousOutput) {
                if walletService.isMine(script: txOut.scriptPubkey) {
                    return true
                }
            }
            return false
        }
    }
    
    var cpfpOutputs: Set<String> {
        return outputs.enumerated().reduce(Set()) { partialResult, result in
            var partialResult = partialResult
            if walletService.isMine(script: result.element.scriptPubkey) {
                partialResult.insert("\(self.id):\(result.offset)")
            }
            return partialResult
        }
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
        let changeBtc = Amount.fromSat(sat: change).toBtc()

        return plus ? changeBtc : -changeBtc
    }
    
    var fee: Amount {
        walletService.calculateFee(inner.transaction)
    }
    
    var feeRate: Double {
        Double(fee.toSat()) / Double(vsize)
    }
}

@Observable
class WalletStore {
    enum SyncStatus: Equatable, CustomStringConvertible {
        case error(String)
        case notStarted
        case syncing
        case synced
        
        var description: String {
            switch self {
            case .error(let err):
                err
            case .notStarted:
                "notStarted"
            case .syncing:
                "syncing"
            case .synced:
                "synced"
            }
        }
    }
    
    var wallet: WalletService
    
    @MainActor
    var balance: Balance = .Zero
    @MainActor
    var payAddress: Address?
    @MainActor
    var ordiAddress: Address?

    @MainActor
    var transactions: [WalletTransaction] = []
    
    @MainActor
    var utxos: [LocalOutput] = []
    @MainActor
    var allUtxos: [LocalOutput] = []
    
    @MainActor
    var syncStatus: SyncStatus = .notStarted
    
    init(wallet: WalletService) {
        self.wallet = wallet
        DispatchQueue.main.async {
            self.load()
        }
    }
    
    func getTxOut(_ op: OutPoint) -> TxOut? {
        return wallet.getTxOut(op: op)
    }
    
    @MainActor
    func load() {
        balance = wallet.getBalance()
        payAddress = wallet.getPayAddress()
        ordiAddress = wallet.getOrdiAddress()
        transactions = wallet.getTransactions().map { ctx in
            WalletTransaction(walletService: wallet, inner: ctx)
        }
        utxos = wallet.getUtxos()
        allUtxos = wallet.getAllUtxos()
    }
    
    @MainActor
    func updateStatus(_ status: SyncStatus) {
        syncStatus = status
    }
    
    func getUtxos() -> [LocalOutput] {
        wallet.getUtxos()
    }
    
    func sync() async throws {
        if await syncStatus != .syncing {
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
    
    func delete() throws {
        try WalletService.deleteAllWallet()
    }
    
    func finish(_ tx: TxBuilder) -> Result<Psbt, CreateTxError> {
        wallet.finish(tx)
    }
    
    func finishBump(_ tx: BumpFeeTxBuilder) -> Result<Psbt, CreateTxError> {
        wallet.finishBump(tx)
    }
    
//    func buildAndSignTx(_ tx: TxBuilder) throws -> (DecentralizedFFI.Transaction, Psbt) {
//        return try wallet.buildAndSignTx(tx)
//    }
    
    func sign(_ psbt: Psbt, _ walletType: WalletType) -> Result<Bool, SignerError> {
        wallet.sign(psbt, walletType: walletType)
    }
    
    func createWalletTx(tx: DecentralizedFFI.Transaction) -> WalletTransaction {
        WalletTransaction(walletService: wallet, inner: CanonicalTx(transaction: tx, chainPosition: ChainPosition.unconfirmed(timestamp: 0)))
    }
    
    func broadcast(_ tx: DecentralizedFFI.Transaction) async -> Result<String, Error> {
        wallet.broadcast(tx)
    }
    
    func broadcastSync(_ tx: DecentralizedFFI.Transaction) -> Result<String, Error> {
        wallet.broadcast(tx)
    }
    
    func insertTxout(op: OutPoint, txout: TxOut) {
        wallet.insertTxOut(op: op, txout: txout)
    }
    
    func isMine(_ script: Script) -> Bool {
        wallet.isMine(script: script)
    }
}
