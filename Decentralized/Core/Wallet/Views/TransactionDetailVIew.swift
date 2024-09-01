//
//  TransactionDetailVIew.swift
//  Decentralized
//
//  Created by Nekilc on 2024/7/11.
//

import AppKit
import BitcoinDevKit
import SwiftUI

struct TransactionDetailView: View {
    @State var tx: CanonicalTx

    @State var esTx: Tx?

    var body: some View {
        ScrollView {
            VStack{
                GroupedBox([
                    GroupedLabeledContent("Txid") {
                        Text(verbatim: tx.id)
                    },
                    GroupedLabeledContent("Status") {
                        Text(verbatim: tx.isComfirmed ? "Comfirmed" : "Uncomfirmed")
                    },
                    GroupedLabeledContent("Fee") {
                        Text(verbatim: "\(esTx?.fee ?? 0) sats")
                    },
                    GroupedLabeledContent("FeeRate") {
                        Text(verbatim: "\((esTx?.fee ?? 0) / (esTx?.size ?? 1)) sats/vB")
                    },
                    HSplitView {
                        Table(of: Vin.self) {
                            TableColumn("Address") { vin in
                                Text(verbatim: "\(vin.prevout.scriptpubkeyAddress ?? "")")
                                    .truncationMode(.middle)
                            }
                            TableColumn("Value") { vin in
                                Text(verbatim: "\(Amount.fromSat(fromSat: vin.prevout.value).displayBtc)")
                            }
                        } rows: {
                            ForEach(esTx?.vin ?? []) { tx in
                                TableRow(tx)
                                    .contextMenu {
                                        Button("copy_address") {
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(tx.prevout.scriptpubkeyAddress ?? "", forType: .string)
                                        }
                                    }
                            }
                        }
                        .truncationMode(.middle)
                        Table(of: Vout.self) {
                            TableColumn("Address") { vout in
                                Text(verbatim: "\(vout.scriptpubkeyAddress ?? "")")
                                    .truncationMode(.middle)
                            }
                            TableColumn("Value") { vout in
                                Text(verbatim: "\(Amount.fromSat(fromSat: vout.value).displayBtc)")
                            }
                        } rows: {
                            ForEach(esTx?.vout ?? []) { tx in
                                TableRow(tx)
                                    .contextMenu {
                                        Button("copy_address") {
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(tx.scriptpubkeyAddress ?? "", forType: .string)
                                        }
                                    }
                            }
                        }
                    }
                    .frame(minHeight: 218)
                ])

                GroupedBox([
                    GroupedLabeledContent("Vsize") {
                        Text(verbatim: "\(tx.transaction.vsize()) kvB")
                    },
                    GroupedLabeledContent("Size") {
                        Text(verbatim: "\(tx.transaction.totalSize()) kB")
                    },
                    GroupedLabeledContent("Version") {
                        Text(verbatim: "\(tx.transaction.version())")
                    },
                    GroupedLabeledContent("Weight") {
                        Text(verbatim: "\(tx.transaction.weight()) kWu")
                    },
                    GroupedLabeledContent("LockTime") {
                        Text(verbatim: "\(tx.transaction.lockTime())")
                    }
                ])
            }
            .padding(.vertical)
        }
        .task {
            fetchTx()
        }
    }

    func fetchTx() {
        NetworkManager.shared.request(urlString: "https://mempool.space/api/tx/\(tx.id)") { (result: Result<Tx, NetworkManager.NetworkError>) in
            switch result {
            case .success(let tx):
                esTx = tx
                logger.info("FetchTx: \(tx.txid)")
            case .failure(let err):
                logger.error("\(err)")
            }
        }
    }
}

// #Preview {
//    TransactionDetailView()
// }
