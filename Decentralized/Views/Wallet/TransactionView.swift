//
//  TransactionView.swift
//  Decentralized
//
//  Created by Nekilc on 2024/5/24.
//

import DecentralizedFFI
import SwiftUI

struct TransactionView: View {
    @Environment(WalletStore.self) var wallet: WalletStore
    @Environment(\.navigate) private var navigate

    @State var selected: Optional<String> = nil

    @State private var sortOrder = [KeyPathComparator(\WalletTransaction.timestamp, order: .reverse)]

    @State var bumpPsbt: Psbt? = nil

    
    var body: some View {
        VStack {
            Table(of: WalletTransaction.self, selection: $selected, sortOrder: $sortOrder) {
                TableColumn("ID") { tx in
                    HStack {
                        Text(tx.id)
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
                                    // CPFP conditions:
                                    // - Input must be contain one of origin' output
                                    // - FeeRate must be more than origin tx
                                    // - Fee must be more than origin tx
                                    NavigationLink("Child Pay For Parent") {
                                        SendScreen(isCPFP: true, selectedOutpointIds: tx.cpfpOutputs)
                                    }
                                }
                                if tx.canRBF {
                                    NavigationLink("Cancel") {
                                        // Cancel conditions:
                                        // - Input must be contain one of origin tx
                                        // - FeeRate must be more than origin tx
                                        // - Fee must be more than origin tx
                                        SendScreen(isRBF: true, selectedOutpointIds: Set(tx.inputs.map { $0.id }))
                                    }
                                    // RBF conditions:
                                    // - FeeRate must be more than origin tx
                                    // - Fee must be more than origin tx
//                                    NavigationLink("Replace By Fee") {
//                                        SendScreen(isRBF: true, selectedOutpointIds: Set(tx.inputs.map { $0.id }))
//                                    }
                                    Button("Replace By Fee") {
                                        onRbf(txid: tx.id)
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
        .toolbar {
            WalletStatusToolbar()
        }
        .navigationDestination(item: $bumpPsbt) { psbt in
            SignScreen(unsignedPsbts: [SignScreen.UnsignedPsbt(psbt: psbt)], deferBroadcastTxs: [])
        }
        
    }


    func onRbf(txid: String) {
        print(txid)
        let bf = BumpFeeTxBuilder(txid: txid, feeRate: FeeRate.from(satPerVb: 10).unwrap())
        if case .success(let psbt) = wallet.finishBump(bf) {
            bumpPsbt = psbt
        }
    }
}

#Preview {
//    TransactionView(walletVm: .init(global: .live))
}
