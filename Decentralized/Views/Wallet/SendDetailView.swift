//
//  SendDetailView.swift
//  Decentralized
//
//  Created by Nekilc on 2024/8/30.
//

import BitcoinDevKit
import SwiftUI

struct SendDetailView: View {
    @Environment(WalletStore.self) var wallet: WalletStore

    var tx: BitcoinDevKit.Transaction

    @Binding var txBuilder: TxBuilder

//    var amountChange: String {
//        walletVm.valueChangeToBtc(tx: tx).displayBtc
//    }
//
//    var fee: UInt64 {
//        walletVm.calcFee(tx: tx)
//    }

//    var feeRate: Double {
//        Double(fee) / Double(tx.vsize())
//    }

    var outputs: [TxOutRow] {
        tx.output().map { txout in
            TxOutRow(inner: txout)
        }
    }

    var body: some View {
        VStack {
            ScrollView {
//                GroupedBox([
//                    Text("\(amountChange)")
//                        .font(.largeTitle)
//                ])
                GroupedBox([
                    GroupedLabeledContent("Txid") {
                        Text(tx.id)
                    },
//                    GroupedLabeledContent("Fee") {
//                        Text("\(fee) sats")
//                    },
//                    GroupedLabeledContent("FeeRate") {
//                        Text("\(feeRate) sats/vb")
//                    },
                    HSplitView {
                        Table(of: TxOutRow.self) {
                            TableColumn("Address") { vout in
                                Text("\(vout.address(network: .bitcoin) ?? "")")
                            }
                            TableColumn("Value") { vout in
                                Text("\(vout.amount.displayBtc)")
                            }
                        } rows: {
                            ForEach(outputs) { out in
                                TableRow(out)
                            }
                        }
                        Table(of: TxOutRow.self) {
                            TableColumn("Address") { vout in
                                Text("\(vout.address(network: .bitcoin) ?? "")")
                            }
                            TableColumn("Value") { vout in
                                Text("\(vout.amount.displayBtc)")
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
                        Text("\(tx.vsize()) kvB")
                    },
                    GroupedLabeledContent("Size") {
                        Text("\(tx.totalSize()) kB")
                    },
                    GroupedLabeledContent("Version") {
                        Text("\(tx.version())")
                    },
                    GroupedLabeledContent("Weight") {
                        Text("\(tx.weight()) kWu")
                    },
                    GroupedLabeledContent("LockTime") {
                        Text("\(tx.lockTime())")
                    }
                ])
            }
            .padding(.top)
            VStack {
                HStack {
                    Spacer()
                    Button {
//                        do {
//                            let (ok, psbt) = try walletVm.sign(txBuilder)
//                            if ok {
//                                print(psbt.serializeHex())
//                            }
//                        } catch {
//                            print(error)
//                        }
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
