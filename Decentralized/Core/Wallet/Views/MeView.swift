//
//  MeView.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/28.
//

import Charts
import SwiftUI

struct CustomFormSection<Content: View>: View {
    let header: String
    let content: Content

    init(_ header: String, @ViewBuilder content: () -> Content) {
        self.header = header
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(header)
                .font(.headline)
                .padding(.bottom, 5)

            VStack(alignment: .leading, spacing: 15) {
                content
            }
            .padding()
//            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}

struct MeView: View {
    @Bindable var walletVm: WalletViewModel

    var body: some View {
        ScrollView {
            VStack {
                GroupedBox([
                    Chart(walletVm.txsChangeGroupDay.prefix(14).reversed(), id: \.0) { date, change in
                        BarMark(
                            x: .value("Date", date.monDayFormat()),
                            y: .value("Value", change)
                        )
                        .foregroundStyle(change > 0 ? .green : .red)
                    }
                    .frame(height: 180)
                ])
                GroupedBox("PayWallet", items: [
                    GroupedLabeledContent("Address") {
                        Text(verbatim: walletVm.global.payAddress)
                    },
                    GroupedLabeledContent("Balance") {
                        Text(verbatim: walletVm.global.balance.displayBtc)
                    },
                    GroupedLabeledContent("QR") {
                        QRCodeView(data: "\(walletVm.global.payAddress)")
                    }
                ])
                GroupedBox("OrdinalsWallet", items: [
                    GroupedLabeledContent("Address") {
                        Text(verbatim: walletVm.global.ordiAddress)
                    },
                    GroupedLabeledContent("QR") {
                        QRCodeView(data: "\(walletVm.global.ordiAddress)")
                    }
                ])
                Spacer()
            }
            .padding(.vertical)
        }
    }
}

#Preview {
    MeView(walletVm: .init(global: .live))
}
