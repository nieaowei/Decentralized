//
//  MeView.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/28.
//

import Charts
import SwiftUI

struct MeView: View {
    @Bindable var walletVm: WalletViewModel

    var body: some View {
        Form {
            Chart(walletVm.txsChangeGroupDay.prefix(14).reversed(), id: \.0) { date, change in
                BarMark(
                    x: .value("Date", date.monDayFormat()),
                    y: .value("Value", change)
                )
                .foregroundStyle(change > 0 ? .green : .red)
            }
            Section("PayWallet") {
                LabeledContent("Address:") {
                    Text(verbatim: walletVm.global.payAddress)
                }
                LabeledContent("Balance:") {
                    Text(verbatim: walletVm.global.balance.displayBtc)
                }
                LabeledContent("QR:") {
                    QRCodeView(data: "\(walletVm.global.payAddress)")
                }
            }
            Section("OrdinalsWallet") {
                LabeledContent("Address:") {
                    Text(verbatim: walletVm.global.ordiAddress)
                }
                LabeledContent("QR:") {
                    QRCodeView(data: "\(walletVm.global.ordiAddress)")
                }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    MeView(walletVm: .init(global: .live))
}
