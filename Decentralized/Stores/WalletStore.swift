//
//  Wallet.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/2.
//

import DecentralizedFFI
import Foundation
import SwiftUI

extension TxDetails: @retroactive Identifiable, @retroactive Hashable, @retroactive Equatable {
    public var id: Txid {
        txid
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.txid)
    }
    
    public static func ==(l: Self, r: Self) -> Bool {
        return l.txid == r.txid
    }
    
    public var timestamp: UInt64 {
        switch chainPosition {
        case .confirmed(let confirmationBlockTime, _):
            confirmationBlockTime.confirmationTime
        case .unconfirmed(let timestamp):
            timestamp ?? Date.nowTs()
        }
    }
    public var isConfirmed: Bool {
        switch chainPosition {
        case .confirmed: true
        case .unconfirmed: false
        }
    }
}

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
    
    var id: Txid {
        txid
    }
    
    var txid: Txid {
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
            if let txOut = walletService.getTxOut(op: txin.previousOutput), self.isExplicitlyRbf {
                return walletService.isMine(script: txOut.scriptPubkey)
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
        case .confirmed(let confirmationBlockTime, _):
            confirmationBlockTime.confirmationTime
        case .unconfirmed(let timestamp):
            timestamp ?? Date.nowTs()
        }
    }

    var date: Date {
        return Calendar.current.startOfDay(for: inner.timestamp.toDate())
    }

    var isConfirmed: Bool {
        switch inner.chainPosition {
        case .confirmed: true
        case .unconfirmed: false
        }
    }

    // todo removed
    var changeAmount: Double {
        let sentAndRecv = walletService.sentAndReceived(inner.transaction)
        let sent = sentAndRecv.sent
        let recv = sentAndRecv.received
        let (plus, change) = if sent.toSat() > recv.toSat() {
            (false, sent.toSat() - recv.toSat())
        } else {
            (true, recv.toSat() - sent.toSat())
        }
        let changeBtc = Amount.fromSat(satoshi: change).toBtc()

        return plus ? changeBtc : -changeBtc
    }

    // todo removed

    var fee: Amount {
        walletService.calculateFee(inner.transaction)
    }

    // todo removed

    var feeRate: Double {
        Double(fee.toSat()) / Double(vsize)
    }
}

@Observable
class WalletStore {
    enum SyncStatus: Equatable, CustomStringConvertible, Sendable {
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
    
    var balance: Balance = .Zero
    var payAddress: Address?
    var ordiAddress: Address?

    var transactions: [TxDetails] = []
    
    var utxos: [LocalOutput] = []
    var allUtxos: [LocalOutput] = []
    
    var syncStatus: SyncStatus = .notStarted
    
    @MainActor
    init(wallet: WalletService) {
        self.wallet = wallet
        load()
    }
    
    func getTxOut(_ op: OutPoint) -> TxOut? {
        return wallet.getTxOut(op: op)
    }
    
    @MainActor
    func load() {
        balance = wallet.getBalance()
        payAddress = wallet.getPayAddress()
        ordiAddress = wallet.getOrdiAddress()
        transactions = wallet.getTransactionDetails()
        utxos = wallet.getUtxos()
        allUtxos = wallet.getAllUtxos()
    }
    
    @MainActor
    func setStatus(_ status: SyncStatus) {
        syncStatus = status
    }
    
    func getUtxos() -> [LocalOutput] {
        wallet.getUtxos()
    }
    
    @MainActor
    func sync() async throws {
        guard syncStatus != .syncing else {
            return
        }
        
        do {
            setStatus(.syncing)
            try await wallet.asyncSync()
            setStatus(.synced)
            load()

        } catch {
            setStatus(.error(error.localizedDescription))
            throw error
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
    
    func createTxDetail(tx: DecentralizedFFI.Transaction) -> TxDetails {
        wallet.createTxDetail(tx)
    }
    
    func broadcast(_ tx: DecentralizedFFI.Transaction) -> Result<Txid, Error> {
        wallet.broadcast(tx)
    }
    
    func broadcastSync(_ tx: DecentralizedFFI.Transaction) -> Result<Txid, Error> {
        wallet.broadcast(tx)
    }
    
    func insertTxout(op: OutPoint, txout: TxOut) {
        wallet.insertTxOut(op: op, txout: txout)
    }
    
    func isMine(_ script: Script) -> Bool {
        wallet.isMine(script: script)
    }
}
