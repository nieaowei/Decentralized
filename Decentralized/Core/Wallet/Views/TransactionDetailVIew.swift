//
//  TransactionDetailVIew.swift
//  Decentralized
//
//  Created by Nekilc on 2024/7/11.
//

import BitcoinDevKit
import SwiftUI
import AppKit

struct TransactionDetailView: View {
    @State var tx: CanonicalTx

    @State var esTx: Tx?

    var body: some View {
        VStack {
            Form {
                Section {
                    LabeledContent("Txid") {
                        Text(verbatim: tx.id)
                    }
                    LabeledContent("Status") {
                        Text(verbatim: tx.isComfirmed ? "Comfirmed" : "Uncomfirmed")
                    }
                    LabeledContent("Fee") {
                        Text(verbatim: "\(esTx?.fee ?? 0) sats")
                    }
                    LabeledContent("FeeRate") {
                        Text(verbatim: "\((esTx?.fee ?? 0) / (esTx?.size ?? 1)) sats/vB")
                    }
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
                                        Button("Copy Address") {
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
                                        Button("Copy Address") {
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(tx.scriptpubkeyAddress ?? "", forType: .string)
                                        }
                                    }
                            }
                        }
                    }
                    .frame(minHeight: 218)
                }

                Section {
                    LabeledContent("Vsize") {
                        Text(verbatim: "\(tx.transaction.vsize()) kvB")
                    }
                    LabeledContent("Size") {
                        Text(verbatim: "\(tx.transaction.totalSize()) kB")
                    }
                    LabeledContent("Version") {
                        Text(verbatim: "\(tx.transaction.version())")
                    }
                    LabeledContent("Weight") {
                        Text(verbatim: "\(tx.transaction.weight()) kWu")
                    }
                    LabeledContent("LockTime") {
                        Text(verbatim: "\(tx.transaction.lockTime())")
                    }
                }
            }
            .formStyle(.grouped)
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
