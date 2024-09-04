//
//  Global.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/3.
//

import BitcoinDevKit
import SwiftUI

@Observable
class GlobalStore {
    let wss: EsploraWss = .shared
    
    var status: EsploraWss.Status
    var fastFee: Int = 0
    
    init() {
        self.status = wss.status
        wss.handleFees = handleFees
        wss.handleNewTx = handleNewTx
    }
    
    func handleFees(fees: Fees) async {
        fastFee = fees.fastestFee
    }
    
    func handleNewTx(tx: EsploraTx) async {
        
    }

    
//    var wallet: WalletService
//    var syncClient: SyncClient
//
//    init(settings: Setting) {
//        let syncClient = switch settings.serverType {
//        case .Esplora:
//            SyncClient.esplora(EsploraClient(url: settings.serverUrl))
//        case .Electrum:
//            SyncClient.electrum(try! ElectrumClient(url: settings.serverUrl))
//        }
//        self.wallet = WalletService(network: settings.network.toBdkNetwork(), syncClient: syncClient)
//        self.syncClient = syncClient
//    }
//
//    func createWallet(words: String, mode: WalletMode) throws {
//        try wallet.createWallet(words: words, mode: mode)
//    }
//
//    func loadWallet() throws {
//        try wallet.loadWalletFromBackup()
//    }
}
