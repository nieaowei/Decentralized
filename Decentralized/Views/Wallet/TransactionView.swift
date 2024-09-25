//
//  TransactionView.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/24.
//

import SwiftUI

struct TransactionView: View {
    @Environment(WalletStore.self) var wallet: WalletStore
    @Environment(\.navigate) private var navigate

    @State var selected: Optional<String> = nil

    @State private var sortOrder = [KeyPathComparator(\WalletTransaction.timestamp, order: .reverse)]

    var body: some View {
        VStack {
            Table(of: WalletTransaction.self, selection: $selected, sortOrder: $sortOrder) {
                TableColumn("ID") { tx in
                    HStack {
                        Text(verbatim: tx.id)
                            .truncationMode(.middle)

                        if tx.canRBF {
                            Image(systemName: "r.circle")
                                .foregroundColor(.green)
                        }
                        if tx.canCPFP {
                            Image(systemName: "c.circle")
                                .foregroundColor(.green)
                        }
                    }
                }
                TableColumn("Value") { tx in
                    Text(tx.changeAmount.displayBtc)
                }
                .width(min: 150, ideal: 150)
                TableColumn("Date", value: \.timestamp) { item in
                    Text(verbatim: item.isComfirmed ? item.timestamp.toDate().commonFormat() : "Uncomfirmed")
                }
                .width(min: 150, ideal: 150)

            } rows: {
                ForEach(wallet.transactions) { tx in
                    TableRow(tx)
                        .contextMenu {
                            NavigationLink("Open Detail") {
                                ScrollView {
                                    TransactionDetailView(tx: tx)
                                }
                            }
                            if !tx.isComfirmed {
                                if tx.canCPFP {
                                    NavigationLink("Child Pay For Parent") {
                                        SendScreen(isCPFP: true, selectedOutpoints: tx.cpfpOutputs)
                                    }
                                }
                                if tx.canRBF {
                                    NavigationLink("Replace By Fee") {
                                        SendScreen(isRBF: true, selectedOutpoints: Set(tx.inputs.map { $0.id }))
                                    }
                                }
                            }
                        }
                }
            }
            .truncationMode(.middle)
            .onChange(of: sortOrder, initial: true) { _, sortOrder in
                wallet.transactions.sort(using: sortOrder)
            }
            .onChange(of: wallet.transactions) { _, _ in
                wallet.transactions.sort(using: sortOrder)
            }
        }
    }
}

#Preview {
//    TransactionView(walletVm: .init(global: .live))
}
