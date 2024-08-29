//
//  OnBoradingView.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/25.
//

import Foundation

import BitcoinDevKit
import SwiftUI

@Observable
class OnBoradingViewModel {
    let bdkClient: BDKClient
    
    @ObservationIgnored
    @AppStorage("isOnBoarding")
    var isOnboarding: Bool?
    
    var showError = false
    var onboardingViewError: AppError?
    
    var isLoading = false
    
    var mnemonic: String = ""
    var mode: WalletMode = .xverse
//    var selectedNetwork: Network = .bitcoin
//
//    var selectedURL: String = "https://mempool.space/api"
    
    init(bdkClient: BDKClient = .live) {
        self.bdkClient = bdkClient
    }
    
    func createWallet() {
        do {
            if mnemonic.isEmpty {
                onboardingViewError = .generic(message: "Please input correct mnemonic")
                showError = true
                return
            }
            isLoading = true
            try bdkClient.createWallet(mnemonic, mode)
            isOnboarding = false
        } catch let error as WalletCreationError {
            DispatchQueue.main.async {
                self.onboardingViewError = .generic(message: error.localizedDescription)
            }
        } catch {
            DispatchQueue.main.async {
                self.onboardingViewError = .generic(message: error.localizedDescription)
                self.showError = true
                self.isLoading = false
            }
        }
    }
}
