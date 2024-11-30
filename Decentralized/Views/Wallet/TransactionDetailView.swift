//
//  TransactionDetailVIew.swift
//  Decentralized
//
//  Created by Nekilc on 2024/7/11.
//

import AppKit
import DecentralizedFFI
import SwiftData
import SwiftUI

struct TransactionDetailView: View {
    @Environment(WalletStore.self) var wallet: WalletStore
    @Environment(SyncClient.self) var syncClient: SyncClient
    @Environment(\.showError) var showError
    @Environment(AppSettings.self) var settings: AppSettings
    @Environment(\.modelContext) var ctx
    @Environment(EsploraClientWrap.self) var esploraClient: EsploraClientWrap

//    let psbt: Psbt?
    let tx: WalletTransaction

    @State
    @MainActor
    var cpfpTx: CPFPChain? = nil

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
                    Text(tx.id)
                },
                GroupedLabeledContent("Status") {
                    Text(tx.isComfirmed ? "Confirmed" : "Unconfirmed")
                },

                GroupedLabeledContent("Fee") {
                    Text("\(tx.fee.toSat()) sats")
                },
                GroupedLabeledContent("Fee Rate") {
                    Text("\(tx.feeRate) sats/vB")
                }
            ])

            if let cpfpTx = cpfpTx {
                GroupedBox([
                    GroupedLabeledContent("Effective Fee Rate(CPFP)") {
                        Text("\(cpfpTx.effectiveFeeRate) sats/vB")
                    },
                    HSplitView {
                        Table(cpfpTx.parents) {
                            TableColumn("Ancestors", value: \.txid)
                        }
                        Table(cpfpTx.childs) {
                            TableColumn("Descendants", value: \.txid)
                        }
                    }.frame(minHeight: 100)
                ])
            }

            GroupedBox([
                HSplitView {
                    Table(of: TxOutRow.self) {
                        TableColumn("Address") { vout in
                            Text(verbatim: "\(vout.formattedScript(network: settings.network.toBitcoinNetwork()))")
                                .truncationMode(.middle)
                                .foregroundStyle(vout.isMine(wallet) ? settings.network.accentColor : .primary)
                        }
                        TableColumn("Value") { vout in
                            Text(verbatim: "\(vout.amount.formatted)")
                                .foregroundStyle(vout.isMine(wallet) ? settings.network.accentColor : .primary)
                        }
                    } rows: {
                        ForEach(inputs) { tx in
                            TableRow(tx)
                                .contextMenu {
                                    Button("Copy Address"){
                                        copyToClipboard(tx.formattedScript(network: settings.network.toBitcoinNetwork()))
                                    }
                                }
                        }
                    }
                    .truncationMode(.middle)
                    Table(of: TxOutRow.self) {
                        TableColumn("Address") { vout in
                            Text("\(vout.formattedScript(network: settings.network.toBitcoinNetwork()))")
                                .truncationMode(.middle)
                                .foregroundStyle(vout.isMine(wallet) ? settings.network.accentColor : .primary)
                        }
                        TableColumn("Value") { vout in
                            Text(verbatim: "\(vout.amount.formatted)")
                                .foregroundStyle(vout.isMine(wallet) ? settings.network.accentColor : .primary)
                        }
                    } rows: {
                        ForEach(outputs) { tx in
                            TableRow(tx)
                                .contextMenu {
                                    Button("Copy Address"){
                                        copyToClipboard(tx.formattedScript(network: settings.network.toBitcoinNetwork()))
                                    }
                                }
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
        .task(id: tx) {
            fetchOutputs()
        }
        .task(id: tx) {
            await fetchCpfpChain()
        }
        .navigationTitle("Transaction Detail")
    }

    func fetchCpfpChain() async {
        // from db
        if case let .success(tx) = CPFPChain.fetchOneByTxid(ctx: ctx, txid: tx.id), let tx {
            if !tx.childs.isEmpty || !tx.parents.isEmpty {
                withAnimation {
                    cpfpTx = tx
                }
                return
            }
        }

        // from network

        let _ = await CPFPChain.fetchChain(esploraClient, tx.id, nil).map { chain in
            if !chain.childs.isEmpty || !chain.parents.isEmpty {
                withAnimation {
                    cpfpTx = chain
                }
                _ = ctx.upsert(chain)
            }
        }.mapError { error in
            logger.error("fetchCpfpChain:\(error)")
            return error
        }
    }

    func fetchOutputs() {
        do {
            var inputs: [TxOutRow] = []
            for txin in tx.inputs {
                // from db
                if let txout = wallet.getTxOut(txin.previousOutput) {
                    inputs.append(TxOutRow(inner: txout))
                    continue
                }
                // from network
                let (txid, vout) = (txin.previousOutput.txid, txin.previousOutput.vout)

                let tx = try syncClient.getTx(txid.description.lowercased())

                if vout < tx.output().count {
                    let txout = tx.output()[Int(txin.previousOutput.vout)]
                    inputs.append(TxOutRow(inner: txout))
                }
            }
            withAnimation {
                self.inputs = inputs
            }
        } catch {
            showError(error, "")
        }
    }
}

#Preview {
//    TransactionDetailView()
}
