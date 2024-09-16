//
//  Global.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/3.
//

import BitcoinDevKit
import SwiftUI

@Observable
class WssStore {
    enum Event: Equatable {
        static func == (lhs: WssStore.Event, rhs: WssStore.Event) -> Bool {
            if case let WssStore.Event.newTx(a) = lhs {
                if case let WssStore.Event.newTx(b) = rhs {
                    return a.id == b.id
                }
            }
            if case let WssStore.Event.txConfirmed(a) = lhs {
                if case let WssStore.Event.txConfirmed(b) = rhs {
                    return a == b
                }
            }
            if case let WssStore.Event.txRemoved(a) = lhs {
                if case let WssStore.Event.txRemoved(b) = rhs {
                    return a.id == b.id
                }
            }
            return false
        }
        
        case newTx(EsploraTx)
        case txConfirmed(String)
        case txRemoved(EsploraTx)
    }
    
    private var  wss: EsploraWss
    
    @MainActor
    var status: EsploraWss.Status = .disconnected
    @MainActor
    var fastFee: Int = 0
    @MainActor
    var event: Event?
    
    init(url: URL) {
        wss = EsploraWss(url: url)
        wss.handleStatus = handleStatus
        wss.handleFees = handleFees
        wss.handleNewTx = handleNewTx
        wss.handleConfirmedTx = handleConfirmedTx
        wss.handleRemovedTx = handleRemovedTx
    }
    
    func updateUrl(_ url: String){
        wss.disconnect()
        
        wss = EsploraWss(url: URL(string: url)!)
        wss.handleStatus = handleStatus
        wss.handleFees = handleFees
        wss.handleNewTx = handleNewTx
        wss.handleConfirmedTx = handleConfirmedTx
        wss.handleRemovedTx = handleRemovedTx
        self.connect()
    }
    
    func connect() {
        wss.connect()
    }
    
    func disconnect() {
        wss.disconnect()
    }
    
    func subscribe(_ datas: [EsploraWss.Data]) {
        wss.subscribe(datas: datas)
    }
    
    func handleStatus(status: EsploraWss.Status) {
        DispatchQueue.main.async {
            self.status = status
        }
    }
    
    func handleFees(fees: Fees) {
        DispatchQueue.main.async {
            if fees.fastestFee != 0 {
                self.fastFee = fees.fastestFee
            }
        }
    }
    
    func handleNewTx(tx: EsploraTx) {
        NotificationManager.sendNotification(title: NSLocalizedString("New Transaction", comment: ""), subtitle: tx.id, body: "")
        wss.subscribe(datas: [.transaction(tx.id)])
        DispatchQueue.main.async {
            self.event = .newTx(tx)
        }
    }
    
    func handleConfirmedTx(tx: String) {
        NotificationManager.sendNotification(title: NSLocalizedString("Transaction Confirmed", comment: ""), subtitle: tx, body: "")
        DispatchQueue.main.async {
            self.event = .txConfirmed(tx)
        }
    }

    func handleRemovedTx(tx: EsploraTx) {
        NotificationManager.sendNotification(title: NSLocalizedString("Transaction Removed", comment: ""), subtitle: tx.id, body: "")
        DispatchQueue.main.async {
            self.event = .txRemoved(tx)
        }
    }
}
