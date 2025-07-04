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
    @Environment(Esplora.self) var esploraClient: Esplora
    @Environment(\.navigate) var navigate: NavigateAction
//    let psbt: Psbt?
    let tx: TxDetails

    @State
    @MainActor
    var cpfpTx: CPFPChain? = nil

    @State
    var inputs: [TxOutRow] = []

    var outputs: [TxOutRow] {
        tx.tx.output().map { out in
            TxOutRow(inner: out)
        }
    }

    var body: some View {
        VStack {
            GroupedBox([
                Text(verbatim: tx.balanceDelta.toBtc().displayBtc)
                    .font(.largeTitle)
            ])
            GroupedBox([
                GroupedLabeledContent("Txid") {
                    Text(verbatim: tx.id.description)
                },
                GroupedLabeledContent("Status") {
                    Text(tx.isConfirmed ? "Confirmed" : "Unconfirmed")
                },

                GroupedLabeledContent("Fee") {
                    Text(verbatim: "\(tx.fee?.toSat() ?? 0) sats")
                },
                GroupedLabeledContent("Fee Rate") {
                    Text(verbatim: "\(tx.feeRate ?? 0) sats/vB")
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
                            let addr = vout.formattedScript(network: settings.network)
                            Text(verbatim: "\(addr)")
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
                                    Button("Copy Address") {
                                        copyToClipboard(tx.formattedScript(network: settings.network))
                                    }
                                }
                        }
                    }
                    .truncationMode(.middle)
                    Table(of: TxOutRow.self) {
                        TableColumn("Address") { vout in
                            Text("\(vout.formattedScript(network: settings.network))")
                                .truncationMode(.middle)
                                .foregroundStyle(vout.isMine(wallet) ? settings.network.accentColor : .primary)
                        }
                        TableColumn("Value") { vout in
                            Text(verbatim: "\(vout.amount.formatted)")
                                .foregroundStyle(vout.isMine(wallet) ? settings.network.accentColor : .primary)
                        }
                    } rows: {
                        ForEach(outputs.enumerated(), id: \.element) { _, output in
                            TableRow(output)
                                .contextMenu {
                                    Button("Copy Address") {
                                        copyToClipboard(output.formattedScript(network: settings.network))
                                    }
//                                    if output.isMine(wallet) {
//                                        NavigationLink("Send") {
//                                            SendScreen(selectedOutpointIds: Set(["\(tx.id):\(index)"]))
//                                        }
//                                    }
                                }
                        }
                    }
                }
                .frame(minHeight: 218)
            ])

            GroupedBox([
                GroupedLabeledContent("Vsize") {
                    Text("\(tx.tx.vsize()) kvB")
                },
                GroupedLabeledContent("Size") {
                    Text("\(tx.tx.totalSize()) kB")
                },
                GroupedLabeledContent("Version") {
                    Text("\(tx.tx.version())")
                },
                GroupedLabeledContent("Weight") {
                    Text("\(tx.tx.weight()) kWu")
                },
                GroupedLabeledContent("LockTime") {
                    Text("\(tx.tx.lockTime())")
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
        logger.info("fetchCpfpChain from db: [\(tx.id)]")

        if case let .success(tx) = CPFPChain.fetchOneByTxid(ctx: ctx, txid: tx.txid), let tx {
            if !tx.childs.isEmpty || !tx.parents.isEmpty {
                withAnimation {
                    cpfpTx = tx
                }
                return
            }
        }

        // from network
        logger.info("fetchCpfpChain from network: [\(tx.id)]")
        let _ = await CPFPChain.fetchChain(esploraClient.getWrap(), tx.txid, nil).map { chain in
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
            for txin in tx.tx.input() {
                // from db
                if let txout = wallet.getTxOut(txin.previousOutput) {
                    inputs.append(TxOutRow(inner: txout))
                    continue
                }
                // from network
                let (txid, vout) = (txin.previousOutput.txid, txin.previousOutput.vout)

                let tx = try syncClient.getTx(txid)

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
