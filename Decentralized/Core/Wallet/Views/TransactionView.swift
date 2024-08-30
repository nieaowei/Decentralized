//
//  TransactionView.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/24.
//

import BitcoinDevKit
import SwiftUI

struct TransactionView: View {
    @State var selected: Optional<String> = nil

    @State var walletVm: WalletViewModel

    @State private var sortOrder = [KeyPathComparator(\CanonicalTx.timestamp, order: .reverse)]

    var body: some View {
        NavigationStack {
            Table(of: CanonicalTx.self, selection: $selected, sortOrder: $sortOrder) {
                TableColumn("ID") { tx in
                    HStack {
                        Text(verbatim: tx.id)
                            .truncationMode(.middle)

                        if tx.transaction.isExplicitlyRbf() {
                            Image(systemName: "r.circle")
                                .foregroundColor(.green)
                        }
                    }
                }
                TableColumn("Value") { item in
                    Text(verbatim: "\(walletVm.valueChangeToBtc(tx: item.transaction).displayBtc)")
                }
                TableColumn("Date", value: \.timestamp) { item in
                    let data = if item.isComfirmed {
                        item.timestamp.toDate().commonFormat()
                    } else {
                        "Uncomfirmed"
                    }
                    Text(verbatim: data)
                }

            } rows: {
                ForEach(walletVm.transactions) { tx in
                    TableRow(tx)
                        .contextMenu {
                            NavigationLink("Open Detail") {
                                TransactionDetailView(tx: tx)
                            }
                            if !tx.isComfirmed {
                                NavigationLink("Child Pay For Parent") {
                                    Button(action:  {}, label: {
                                        Text("Child Pay For Parent")
                                    })
                                }
                                if tx.transaction.isExplicitlyRbf(){
                                    NavigationLink("Replace By Fee") {
                                        Button(action:  {}, label: {
                                            Text("Replace By Fee")
                                        })
                                    }
                                }
                                
                            }
                        }
                }
            }
            .onTapGesture {
                logger.info("\(selected ?? "")")
            }
            .truncationMode(.middle)
            .onChange(of: sortOrder) { _, sortOrder in
                walletVm.transactions.sort(using: sortOrder)
            }
        }
    }
}

#Preview {
    TransactionView(walletVm: .init(global: .live))
}
