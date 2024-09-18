//
//  WalletSettings.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/17.
//

import SwiftUI

struct WalletSettings: View {
    @Environment(AppSettings.self) private var settings: AppSettings
    @Environment(\.showError) private var showError
    @Environment(\.dismissWindow) private var dismissWindow

    @Environment(\.modelContext) private var ctx

    var body: some View {
        Form {
            Section {
                LabeledContent("Export Mnemonic") {
                    Button("Export Mnemonic") {}
                }
                LabeledContent("Reset Wallet") {
                    Button("Reset Wallet") {
                        onReset()
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    func onReset() {
        do {
            try WalletService.deleteAllWallet()
            try ctx.delete(model: Contact.self)
            settings.isOnBoarding = true
            dismissWindow()
        } catch {
            showError(error, "Delete")
        }
    }
}
