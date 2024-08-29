//
//  HomeViewModel.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/27.
//

import BitcoinDevKit
import Foundation
import Observation
import SwiftUI

@Observable
class GlobalViewModel {
    @ObservationIgnored
    static var live: GlobalViewModel = .init()
    
    let bdkClient: BDKClient
    var wss: MempoolService = .init()
    var notify: NotificationManager = .init()
    
    var payAddress: String = ""
    var ordiAddress: String = ""
    var balance: Amount = .fromSat(fromSat: 0)

    var showAlert: Bool = false
    var error: AppError?
    
    @ObservationIgnored
    @AppStorage("isOnBoarding")
    var isOnboarding: Bool?
    
    var tabIndex: Sections = .wallet( .me)

    var walletSyncState: WalletSyncState = .notStarted
    
    init(bdkClient: BDKClient = .live) {
        self.bdkClient = bdkClient
    }
    
    func loadWallet() {
        do {
            try self.bdkClient.loadWallet()
            self.payAddress = try self.bdkClient.getPayAddress().description
            self.ordiAddress = try self.bdkClient.getOrdiAddress().description
            self.getBalance()
        } catch let error as DescriptorError {
            logger.error("[loadWallet] \(error.localizedDescription)")
            self.error = .generic(message: error.localizedDescription)
            self.showAlert = true
        
        } catch {
            logger.error("[loadWallet] \(error.localizedDescription)")
            self.error = .generic(message: error.localizedDescription)
            self.showAlert = true
        }
    }
    
    func sync() async {
        self.walletSyncState = .syncing
        do {
            try await self.bdkClient.sync()
            
            self.walletSyncState = .synced
        } catch {
            logger.error("[sync] \(error)")
            self.walletSyncState = .error(error)
            self.showAlert = true
        }
    }
    
    func resync() async {
        if self.walletSyncState == .synced {
            self.walletSyncState = .syncing
            do {
                try await self.bdkClient.sync()
                self.walletSyncState = .synced
            } catch {
                logger.error("[sync] \(error)")
                self.walletSyncState = .error(error)
                self.showAlert = true
            }
        }
    }
    
    func delete() {
        do {
            try self.bdkClient.deleteWallet()
            self.isOnboarding = true
        } catch {
            logger.error("[delete] \(error.localizedDescription)")

            self.error = .generic(message: error.localizedDescription)
            self.showAlert = true
        }
    }
    
    func getBalance() {
        do {
            self.balance = try self.bdkClient.getBalance().total
        } catch {
            logger.error("[getBalance] \(error.localizedDescription)")
            self.error = .generic(message: error.localizedDescription)
            self.showAlert = true
        }
    }
}
