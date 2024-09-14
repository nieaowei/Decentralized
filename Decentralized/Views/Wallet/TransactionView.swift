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

                        if tx.isExplicitlyRbf {
                            Image(systemName: "r.circle")
                                .foregroundColor(.green)
                        }
                    }
                }
                TableColumn("Value") { tx in
                    Text(tx.changeAmount.displayBtc)
                }
                .width(min: 150, ideal: 150)
                TableColumn("Date", value: \.timestamp) { item in
                    let data = if item.isComfirmed {
                        item.timestamp.toDate().commonFormat()
                    } else {
                        "Uncomfirmed"
                    }
                    Text(verbatim: data)
                }
                .width(min: 150, ideal: 150)

            } rows: {
                ForEach(wallet.transactions) { tx in
                    TableRow(tx)
                        .contextMenu {
                            NavigationLink("Open Detail") {
                                ScrollView{
                                    TransactionDetailView(tx: tx)
                                }
                            }
                            if !tx.isComfirmed {
                                NavigationLink("Child Pay For Parent") {
                                    Button(action: {}, label: {
                                        Text("Child Pay For Parent")
                                    })
                                }
                                if tx.isExplicitlyRbf {
                                    NavigationLink("Replace By Fee") {
                                        Button(action: {}, label: {
                                            Text("Replace By Fee")
                                        })
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
