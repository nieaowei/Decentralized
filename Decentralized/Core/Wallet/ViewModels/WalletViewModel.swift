//
//  WalletViewModel.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/23.
//

import BitcoinDevKit
import Foundation
import Observation
import SwiftUI

@Observable
class WalletViewModel {

    var global: GlobalViewModel

    var transactions: [CanonicalTx] = []
    var utxos: [LocalOutput] = []

    var walletViewError: AppError?
    var showAlert: Bool = false

    var txsGroupDay: [Date: [CanonicalTx]] {
        self.getTransactionsGroupByDay(self.transactions)
    }

    var txsChangeGroupDay: [(Date, Double)] {
        self.getTransactionsChangeGroupByDay(self.transactions).sorted { day1, day2 in
            day1.day > day2.day
        }
    }

    init(global: GlobalViewModel) {
        self.global = global
        self.global.loadWallet()
        self.refresh()
    }
    
    func refresh(){
        self.getTransactions()
        self.getUtxos()
        self.global.getBalance()
    }

    func getTransactions() {
        do {
            let transactionDetails = try global.bdkClient.transactions()
            self.transactions = transactionDetails.sorted(using: KeyPathComparator(\.timestamp, order: .reverse))
        } catch let error as WalletError {
            logger.error("[getTransactions] \(error.localizedDescription)")
            self.walletViewError = .generic(message: error.localizedDescription)
            self.showAlert = true
        } catch {
            logger.error("[getTransactions] \(error.localizedDescription)")
            self.walletViewError = .generic(message: error.localizedDescription)
            self.showAlert = true
        }
    }

    func getTransactionsChangeGroupByDay(_ txs: [CanonicalTx]) -> [(day: Date, value: Double)] {
        let txs = self.getTransactionsGroupByDay(txs)
        var res: [(Date, Double)] = []
        for (date, txss) in txs {
            let totalQuantityForDate = txss.reduce(Double(0)) { $0 + self.valueChangeToBtc(tx: $1.transaction) }

            res.append((day: date, value: totalQuantityForDate))
        }
        return res
    }

    func getTransactionsGroupByDay(_ txs: [CanonicalTx]) -> [Date: [CanonicalTx]] {
        var res: [Date: [CanonicalTx]] = [:]
        for tx in txs {
            if res[tx.date] != nil {
                res[tx.date]!.append(tx)
            } else {
                res[tx.date] = [tx]
            }
        }
        return res
    }

    func getUtxos() {
        do {
            let utxos = try global.bdkClient.utxos()
            self.utxos = utxos.sorted(using: KeyPathComparator(\.txout.value, order: .reverse))

        } catch let error as WalletError {
            logger.error("[getUtxos] \(error.localizedDescription)")
            self.walletViewError = .generic(message: error.localizedDescription)
            self.showAlert = true
        } catch {
            logger.error("[getUtxos] \(error.localizedDescription)")
            self.walletViewError = .generic(message: error.localizedDescription)
            self.showAlert = true
        }
    }

    func calcFee(tx: BitcoinDevKit.Transaction) -> UInt64 {
        do {
            return try global.bdkClient.calculateFee(tx)
        } catch {
            return 0
        }
    }

    func sentAndRecv(tx: BitcoinDevKit.Transaction) -> (Amount, Amount) {
        do {
            let v = try global.bdkClient.sentAndReceived(tx)
            return (v.sent, v.received)
        } catch {
            return (Amount.fromSat(fromSat: 0), Amount.fromSat(fromSat: 0))
        }
    }

    func valueChangeToBtc(tx: BitcoinDevKit.Transaction) -> Double {
        let (sent, recv) = self.sentAndRecv(tx: tx)

        let (plus, change) = if sent.toSat() > recv.toSat() {
            (false, sent.toSat() - recv.toSat())
        } else {
            (true, recv.toSat() - sent.toSat())
        }
        let changeBtc = Amount.fromSat(fromSat: change).toBtc()

        return plus ? changeBtc : -changeBtc
    }
}
