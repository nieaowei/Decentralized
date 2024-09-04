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

    var body: some View {
        ScrollView {
            VStack {
//                GroupedBox([
//                    Chart(walletVm.txsChangeGroupDay.prefix(14).reversed(), id: \.0) { date, change in
//                        BarMark(
//                            x: .value("Date", date.monDayFormat()),
//                            y: .value("Value", change)
//                        )
//                        .foregroundStyle(change > 0 ? .green : .red)
//                    }
//                    .frame(height: 180)
//                ])
                GroupedBox("PayWallet", items: [
                    GroupedLabeledContent("Address") {
                        Text(wallet.payAddress?.description ?? "")
                    },
                    GroupedLabeledContent("Balance") {
                        Text(wallet.balance.displayBtc)
                    },
                    GroupedLabeledContent("QR") {
                        QRCodeView(data: wallet.payAddress?.description)
                    }
                ])
                GroupedBox("OrdinalsWallet", items: [
                    GroupedLabeledContent("Address") {
                        Text(verbatim: wallet.ordiAddress?.description ?? "")
                    },
                    GroupedLabeledContent("QR") {
                        QRCodeView(data: wallet.ordiAddress?.description)
                    }
                ])
                Spacer()
            }
            .padding(.vertical)
        }
    }
}

#Preview {
//    MeView(walletVm: .init(global: .live))
}
