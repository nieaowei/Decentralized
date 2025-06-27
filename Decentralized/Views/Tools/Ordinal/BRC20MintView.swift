//
//  Untitled.swift
//  Decentralized
//
//  Created by Nekilc on 2025/6/16.
//
import DecentralizedFFI
import SwiftUI

struct BRC20Json: Codable {
    var p: String = "brc-20"
    var tick: String
    var op: String
    var amt: String?
    var max: String?
    var lim: String?
}

struct BRC20MintView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(WalletStore.self) private var wallet
    @Environment(WssStore.self) private var wss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.showError) private var showError

    @Binding var mintPair: OrdinalMintPair?

    @State var tick: String = ""
    @State var reciver: String = ""
    @State var op: String = "transfer"
    @State var amount: Double = 0
    @State var deployMax: Double = 0
    @State var limit: Double = 0
    @State var feeRate: UInt64 = 0

    var body: some View {
        Form {
            Section {
                Picker("Type", selection: $op) {
                    Text("Transfer")
                        .tag("transfer")
                    Text("Mint")
                        .tag("mint")
                    Text("Deploy")
                        .tag("deploy")
                }
                .pickerStyle(.radioGroup)
                TextField("Tick", text: $tick, prompt: Text(verbatim: "pizza"))
                switch op {
                    case "transfer":
                        TextField("Amount", value: $amount, formatter: NumberFormatter())
                    case "mint":
                        TextField("Amount", value: $amount, formatter: NumberFormatter())
                    case "deploy":
                        TextField("Deploy Max", value: $deployMax, formatter: NumberFormatter())
                        TextField("Limit Per Mint", value: $limit, formatter: NumberFormatter())
                    default:
                        EmptyView()
                }

                TextField("Reciver", text: $reciver)
                TextField("Fee Rate", value: $feeRate, formatter: NumberFormatter())
            }
            .sectionActions {
                GlassButton.primary("Build", action: onConfirm)
            }
        }
        .formStyle(.grouped)
        .onAppear {
            reciver = wallet.ordiAddress!.description
            feeRate = wss.fastFee
        }
    }

    func onConfirm() {
        Task {
            if reciver.isEmpty {
                showError(nil, "Reciver is empty")
                return
            }
            if tick.isEmpty {
                showError(nil, "Tick is empty")
                return
            }
            if feeRate <= 1 {
                showError(nil, "Fee Rate must be > 1")
                return
            }
            var data = BRC20Json(tick: tick, op: op)
            switch op {
                case "transfer":
                    data.amt = String(amount)
                case "mint":
                    data.amt = String(amount)
                case "deploy":
                    data.lim = String(limit)
                    data.max = String(deployMax)
                default:
                    data.amt = String(amount)
            }
            let jsonData = try JSONEncoder().encode(data)

            let utxos = wallet.utxos.sorted { l, r in
                l.txout.value > r.txout.value
            }
            let r = await mintOrd(network: settings.network, utxos: utxos, file: NamedFile(name: "brc20.json", data: jsonData), payAddress: wallet.payAddress!.description, toAddr: reciver, feeRate: feeRate, postage: nil)
            switch r {
                case .success(let success):
                    mintPair = OrdinalMintPair(commitPsbt: success.commitPsbtTx, revealTx: success.revealTx)
                    Task {
                        guard case .success(let commitTx) = success.commitPsbtTx.extractTransaction() else {
                            return
                        }
                        
                        let ordi = OrdinalHistory(commitTxId: commitTx.computeTxid(), revealTxId: success.revealTx.computeTxid(), commitPsbtHex: success.commitPsbtTx.serializeHex(), revealTxHex: success.revealTx.serializeHex(), revealPk: success.revealPrivateKey)
                    }

                case .failure(let failure):
                    showError(failure, "Check params")
            }
        }
    }
}
