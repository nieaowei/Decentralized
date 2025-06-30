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
    @Environment(\.showError) private var showError

    @State var selected: Optional<Txid> = nil

    @State private var sortOrder = [KeyPathComparator(\TxDetails.timestamp, order: .reverse)]

    @State var bumpPsbt: Psbt? = nil

    
    var body: some View {
        VStack {
            Table(of: TxDetails.self, selection: $selected, sortOrder: $sortOrder) {
                TableColumn("ID") { tx in
                    HStack {
                        Text(tx.id.description)
                            .truncationMode(.middle)

                        if tx.canRbf {
                            Image(systemName: "r.circle")
                                .foregroundColor(.green)
                        }
                        if tx.canCpfp {
                            Image(systemName: "c.circle")
                                .foregroundColor(.green)
                        }
                    }
                }
                TableColumn("Value") { tx in
                    Text(tx.balanceDelta.toBtc().displayBtc)
                }
                .width(min: 150, ideal: 150)
                TableColumn("Date", value: \.timestamp) { item in
                    Text(verbatim: item.isConfirmed ? item.timestamp.toDate().commonFormat() : "Uncomfirmed")
                }
                .width(min: 150, ideal: 150)

            } rows: {
//                ForEach(wallet.transactions) { tx in
//                    TableRow(tx)
//                }
                ForEach(wallet.transactions) { tx in
                    TableRow(tx)
                        .contextMenu {
                            NavigationLink("Open Detail") {
                                ScrollView {
                                    TransactionDetailView(tx: tx)
                                }
                            }
                            if !tx.isConfirmed {
                                if tx.canCpfp {
                                    // CPFP conditions:
                                    // - Input must be contain one of origin' output
                                    // - FeeRate must be more than origin tx
                                    // - Fee must be more than origin tx
                                    NavigationLink("Child Pay For Parent") {
//                                        SendScreen(isCPFP: true, selectedOutpointIds: tx.cpfpOutputs)
                                    }
                                }
                                if tx.canRbf {
                                    NavigationLink("Cancel") {
                                        // Cancel conditions:
                                        // - Input must be contain one of origin tx
                                        // - FeeRate must be more than origin tx
                                        // - Fee must be more than origin tx
                                        SendScreen(isRBF: true, selectedOutpointIds: Set(tx.tx.input().map { $0.id }))
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
                }//        WalletTransaction(walletService: wallet, inner: CanonicalTx(transaction: tx, chainPosition: ChainPosition.unconfirmed(timestamp: 0)))

            }
            .truncationMode(.middle)
//            .onChange(of: sortOrder, initial: true) { _, sortOrder in
//                wallet.transactions.sort(using: sortOrder)
//            }
//            .onChange(of: wallet.transactions) { _, _ in
//                wallet.transactions.sort(using: sortOrder)
//            }
            
        }
        .toolbar {
            WalletStatusToolbar()
        }
//        .navigationDestination(item: $bumpPsbt) { psbt in
//            TxSignScreen(unsignedPsbts: [TxSignScreen.UnsignedPsbt(psbt: psbt)], deferBroadcastTxs: [])
//        }
        
    }


    func onRbf(txid: Txid) {
        print(txid)
        let bf = BumpFeeTxBuilder(txid: txid, feeRate: FeeRate.from(satPerVb: 10).unwrap())
        switch wallet.finishBump(bf){
            
        case .success(let psbt):
            navigate(.push(.wallet(.txSign(unsignedPsbts: [.init(psbt: psbt)]))))

        case .failure(let error):
            showError(error,"")
        }
//        if case .success(let psbt) = wallet.finishBump(bf) {
//            bumpPsbt = psbt
//        }
    }
}

#Preview {
//    TransactionView(walletVm: .init(global: .live))
}
