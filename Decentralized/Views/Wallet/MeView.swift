//
//  MeView.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/28.
//

import Charts
import SwiftUI

struct MeView: View {
    @Environment(WalletStore.self) var wallet: WalletStore

    @State var showQR: String?
    var body: some View {
        ScrollView {
            VStack {
                GroupedBox("PayWallet", items: [
                    GroupedLabeledContent("Address") {
                        Text(wallet.payAddress?.description ?? "")
                    },
                    GroupedLabeledContent("Balance") {
                        Text(wallet.balance.total.formatted)
                    },
                    GroupedLabeledContent("QR") {
                        QRCodeView(data: wallet.payAddress?.description)
                            .onTapGesture {
                                showQR = wallet.payAddress?.description
                            }
                    }
                ])
                GroupedBox("OrdinalsWallet", items: [
                    GroupedLabeledContent("Address") {
                        Text(verbatim: wallet.ordiAddress?.description ?? "")
                    },
                    GroupedLabeledContent("QR") {
                        QRCodeView(data: wallet.ordiAddress?.description)
                            .onTapGesture {
                                showQR = wallet.ordiAddress?.description
                            }
                    }
                ])
                Spacer()
            }
            .padding(.vertical)
        }
        .toolbar {
            WalletStatusToolbar()
        }
        .sheet(item: $showQR) { qr in
            VStack {
                QRCodeView(data: qr, size: 180)
                PrimaryButton("OK") {
                    showQR = nil
                }
            }
            .padding(.all)
        }
    }
}

#Preview {
//    MeView()
}
