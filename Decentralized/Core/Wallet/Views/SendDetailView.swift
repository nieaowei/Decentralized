//
//  SendDetailView.swift
//  Decentralized
//
//  Created by Nekilc on 2024/8/30.
//

import BitcoinDevKit
import SwiftUI

struct SendDetailView: View {
    @Bindable var walletVm: WalletViewModel

    var tx: BitcoinDevKit.Transaction

    @Binding var txBuilder: TxBuilder

//    @State var inputs: [TxOut] = []

    var outputs: [TxOutRow] {
        tx.output().map { txout in
            TxOutRow(inner: txout)
        }
    }

    var body: some View {
        VStack {
            ScrollView {
                GroupedBox([
                    GroupedLabeledContent("Txid") {
                        Text(verbatim: tx.id)
                    },
                    GroupedLabeledContent("Fee") {
                        Text(verbatim: "\(walletVm.calcFee(tx: tx)) sats")
                    },
                    HSplitView {
                        Table(of: TxOutRow.self) {
                            TableColumn("Address") { vout in
                                Text(verbatim: "\(vout.address(network: .bitcoin) ?? "")")
                            }
                            TableColumn("Value") { vout in
                                Text(verbatim: "\(vout.amount.displayBtc)")
                            }
                        } rows: {
                            ForEach(outputs) { out in
                                TableRow(out)
                            }
                        }
                        Table(of: TxOutRow.self) {
                            TableColumn("Address") { vout in
                                Text(verbatim: "\(vout.address(network: .bitcoin) ?? "")")
                            }
                            TableColumn("Value") { vout in
                                Text(verbatim: "\(vout.amount.displayBtc)")
                            }
                        } rows: {
                            ForEach(outputs) { out in
                                TableRow(out)
                            }
                        }
                    }
                    .frame(minHeight: 218)

                ])

                GroupedBox([
                    GroupedLabeledContent("Vsize") {
                        Text(verbatim: "\(tx.vsize()) kvB")
                    },
                    GroupedLabeledContent("Size") {
                        Text(verbatim: "\(tx.totalSize()) kB")
                    },
                    GroupedLabeledContent("Version") {
                        Text(verbatim: "\(tx.version())")
                    },
                    GroupedLabeledContent("Weight") {
                        Text(verbatim: "\(tx.weight()) kWu")
                    },
                    GroupedLabeledContent("LockTime") {
                        Text(verbatim: "\(tx.lockTime())")
                    }
                ])
            }
            .padding(.top)
            VStack {
                HStack {
                    Spacer()
                    Button {
                        do {
                            let (ok, psbt) = try walletVm.sign(txBuilder)
                            if ok {
                                print(psbt.serializeHex())
                            }
                        } catch {
                            print(error)
                        }
                    } label: {
                        Text("Sign")
                    }
                    .primary()
                }
            }
            .padding(.all)
        }
        .task {
            print(tx.output())
        }
//        .task {
//            let prevouts = tx.input().map { txin in
//                txin.previousOutput
//            }
//            do {
//                for prevout in prevouts {
//                    let resp = try walletVm.global.esploraClient.getTx(txid: prevout.txid.lowercased())
//                    let addressValue = resp.output()[Int(prevout.vout)]
//                    inputs.append(addressValue)
//                }
//
//            } catch {}
//        }
    }
}
