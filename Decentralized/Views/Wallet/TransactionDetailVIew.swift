//
//  TransactionDetailVIew.swift
//  Decentralized
//
//  Created by Nekilc on 2024/7/11.
//

import AppKit
import BitcoinDevKit
import SwiftData
import SwiftUI

struct TransactionDetailView: View {
    @Environment(WalletStore.self) var wallet: WalletStore
    @Environment(SyncClient.self) var syncClient: SyncClient
    @Environment(\.showError) var showError
    @Environment(AppSettings.self) var settings: AppSettings
    @Environment(\.modelContext) var ctx

    var tx: WalletTransaction

    @State
    @MainActor
    var cpfpTx: CpfpChain? = nil

    @State
    var inputs: [TxOutRow] = []

    var outputs: [TxOutRow] {
        tx.outputs.map { out in
            TxOutRow(inner: out)
        }
    }

    var body: some View {
        VStack {
            GroupedBox([
                Text("\(tx.changeAmount.displayBtc)")
                    .font(.largeTitle)
            ])
            GroupedBox([
                GroupedLabeledContent("Txid") {
                    Text(verbatim: tx.id)
                },
                GroupedLabeledContent("Status") {
                    Text(verbatim: tx.isComfirmed ? "Comfirmed" : "Uncomfirmed")
                },

                GroupedLabeledContent("Fee") {
                    Text(verbatim: "\(tx.fee) sats")
                },
                GroupedLabeledContent("Fee Rate") {
                    Text("\((tx.fee) / (tx.vsize)) sats/vB")
                },
                { if let cpfpTx = cpfpTx {
                    return GroupedLabeledContent("Effective Fee Rate(CPFP)") {
                        Text("\(cpfpTx.effectiveFeeRate) sats/vB")
                    }
                } else {
                    return EmptyView()
                }}(),
                { if let cpfpTx = cpfpTx {
                    return HSplitView {
                        Table(cpfpTx.parents) {
                            TableColumn("Ancestors", value: \.txid)
                        }
                        Table(cpfpTx.childs) {
                            TableColumn("Descendants", value: \.txid)
                        }
                    }.frame(minHeight: 100)
                } else {
                    return EmptyView()
                }}(),
               
            ])
            
            GroupedBox([
                HSplitView {
                    Table(of: TxOutRow.self) {
                        TableColumn("Address") { vout in
                            Text(verbatim: "\(try! vout.address(network: settings.network.toBdkNetwork()))")
                                .truncationMode(.middle)
                        }
                        TableColumn("Value") { vout in
                            Text(verbatim: "\(vout.amount.displayBtc)")
                        }
                    } rows: {
                        ForEach(inputs) { tx in
                            TableRow(tx)
                        }
                    }
                    .truncationMode(.middle)
                    Table(of: TxOutRow.self) {
                        TableColumn("Address") { vout in
                            Text(verbatim: "\(try! vout.address(network: settings.network.toBdkNetwork()))")
                                .truncationMode(.middle)
                        }
                        TableColumn("Value") { vout in
                            Text(verbatim: "\(vout.amount.displayBtc)")
                        }
                    } rows: {
                        ForEach(outputs) { tx in
                            TableRow(tx)
                        }
                    }
                }
                .frame(minHeight: 218)
            ])

            GroupedBox([
                GroupedLabeledContent("Vsize") {
                    Text("\(tx.vsize) kvB")
                },
                GroupedLabeledContent("Size") {
                    Text("\(tx.totalSize) kB")
                },
                GroupedLabeledContent("Version") {
                    Text("\(tx.version)")
                },
                GroupedLabeledContent("Weight") {
                    Text("\(tx.weight) kWu")
                },
                GroupedLabeledContent("LockTime") {
                    Text("\(tx.lockTime)")
                }
            ])
        }
        .padding(.vertical)
        .task {
            fetchOutputs()
        }
        .task {
            do {
                let id = tx.id
                let p = #Predicate<CpfpChain> { chain in chain.txid == id }
                let txs = try ctx.fetch(FetchDescriptor(predicate: p))
                if !txs.isEmpty {
                    cpfpTx = txs[0]
                    return
                }
                let cpfp = try await CpfpChain.fetchChain(EsploraClient(url: "https://mempool.space/testnet4/api"), tx.id, nil)
                cpfpTx = cpfp
                
                ctx.insert(cpfp)
            } catch {
                print(error)
            }
        }
        .navigationTitle("Transaction Detail")
    }

    func fetchOutputs() {
        do {
            for txin in tx.inputs {
                if let txout = wallet.getTxOut(txin.previousOutput) {
                    inputs.append(TxOutRow(inner: txout))
                } else {
                    let (txid, vout) = (txin.previousOutput.txid, txin.previousOutput.vout)

                    let tx = try syncClient.getTx(txid.lowercased())

                    if vout < tx.output().count {
                        let txout = tx.output()[Int(txin.previousOutput.vout)]
                        inputs.append(TxOutRow(inner: txout))
                    }
                }
            }
        } catch {
            showError(error, "")
        }
    }
}
























/// Cause in cpu 100%
struct TransactionDetailView1<Action: View>: View {
    @Environment(WalletStore.self) var wallet: WalletStore
    @Environment(SyncClient.self) var syncClient: SyncClient
    @Environment(\.showError) var showError
    @Environment(AppSettings.self) var settings: AppSettings

    var tx: WalletTransaction

    @State
    var inputs: [TxOutRow] = []

    @ViewBuilder
    let action: Action

    init(tx: WalletTransaction, @ViewBuilder action: () -> Action = { EmptyView() }) {
        self.tx = tx
        self.action = action()
    }

    var outputs: [TxOutRow] {
        tx.outputs.map { out in
            TxOutRow(inner: out)
        }
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    GroupedBox([
                        Text("\(tx.changeAmount.displayBtc)")
                            .font(.largeTitle)
                    ])
                    GroupedBox([
                        GroupedLabeledContent("Txid") {
                            Text(verbatim: tx.id)
                        },
                        GroupedLabeledContent("Status") {
                            Text(verbatim: tx.isComfirmed ? "Comfirmed" : "Uncomfirmed")
                        },

                        GroupedLabeledContent("Fee") {
                            Text(verbatim: "\(tx.fee) sats")
                        },
                        GroupedLabeledContent("FeeRate") {
                            Text(verbatim: "\((tx.fee) / (tx.vsize)) sats/vB")
                        },
                        HSplitView {
                            Table(of: TxOutRow.self) {
                                TableColumn("Address") { vout in
                                    Text(verbatim: "\(try! vout.address(network: settings.network.toBdkNetwork()))")
                                        .truncationMode(.middle)
                                }
                                TableColumn("Value") { vout in
                                    Text(verbatim: "\(vout.amount.displayBtc)")
                                }
                            } rows: {
                                ForEach(inputs) { tx in
                                    TableRow(tx)
                                }
                            }
                            .truncationMode(.middle)
                            Table(of: TxOutRow.self) {
                                TableColumn("Address") { vout in
                                    Text(verbatim: "\(try! vout.address(network: settings.network.toBdkNetwork()))")
                                        .truncationMode(.middle)
                                }
                                TableColumn("Value") { vout in
                                    Text(verbatim: "\(vout.amount.displayBtc)")
                                }
                            } rows: {
                                ForEach(outputs) { tx in
                                    TableRow(tx)
                                }
                            }
                        }
                        .frame(minHeight: 218)
                    ])

                    GroupedBox([
                        GroupedLabeledContent("Vsize") {
                            Text("\(tx.vsize) kvB")
                        },
                        GroupedLabeledContent("Size") {
                            Text("\(tx.totalSize) kB")
                        },
                        GroupedLabeledContent("Version") {
                            Text("\(tx.version)")
                        },
                        GroupedLabeledContent("Weight") {
                            Text("\(tx.weight) kWu")
                        },
                        GroupedLabeledContent("LockTime") {
                            Text("\(tx.lockTime)")
                        }
                    ])
                }
                .padding(.vertical)
                .task {
                    fetchOutputs()
                }
            }
            self.action
        }
    }

    func fetchOutputs() {
        do {
            for txin in tx.inputs {
                if let txout = wallet.getTxOut(txin.previousOutput) {
                    inputs.append(TxOutRow(inner: txout))
                } else {
                    let (txid, vout) = (txin.previousOutput.txid, txin.previousOutput.vout)

                    let tx = try syncClient.getTx(txid.lowercased())

                    if vout < tx.output().count {
                        let txout = tx.output()[Int(txin.previousOutput.vout)]
                        inputs.append(TxOutRow(inner: txout))
                    }
                }
            }

        } catch {
            showError(error, "")
        }
    }
}

#Preview {
//    TransactionDetailView()
}
