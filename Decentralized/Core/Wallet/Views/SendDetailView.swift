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

    var esTx: Tx {
        let vout: [Vout] = tx.output().map { (txout: TxOut) in
            return Vout(scriptpubkey: txout.scriptPubkey.toBytes().description, scriptpubkeyASM: "", scriptpubkeyType: .opReturn, scriptpubkeyAddress: try? Address.fromScript(script: txout.scriptPubkey, network: .bitcoin).description, value: txout.value)
        }

//        let vin = tx.input().map { vin in
//            Vin(txid: vin.id, vout: vin.previousOutput.vout, prevout: <#T##Vout#>, scriptsig: <#T##String#>, scriptsigASM: <#T##String#>, witness: <#T##[String]?#>, isCoinbase: <#T##Bool#>, sequence: <#T##Int#>, innerWitnessscriptASM: <#T##String?#>, innerRedeemscriptASM: <#T##String?#>)
//        }
        return Tx(txid: tx.id, version: Int(tx.version()), locktime: Int(tx.lockTime()), vin: [], vout: vout, size: Int(tx.totalSize()), weight: Int(tx.weight()), sigops: 0, fee: Int(walletVm.calcFee(tx: tx)), status: Status(confirmed: false, blockHeight: 0, blockHash: "", blockTime: 0))
    }

    var body: some View {
        VStack {
            Form {
                Section {
                    LabeledContent("Txid") {
                        Text(verbatim: tx.id)
                    }
//                    LabeledContent("Status") {
//                        Text(verbatim: tx.isComfirmed ? "Comfirmed" : "Uncomfirmed")
//                    }
                    LabeledContent("Fee") {
                        Text(verbatim: "\(walletVm.calcFee(tx: tx)) sats")
                    }
//                    LabeledContent("FeeRate") {
//                        Text(verbatim: "\((esTx?.fee ?? 0) / (esTx?.size ?? 1)) sats/vB")
//                    }
                    HSplitView {
                        Table(of: TxIn.self) {
                            TableColumn("Address") { txin in
                                
//                                Text(verbatim: "\(vin.previousOutput.txid ?? "")")
//                                    .truncationMode(.middle)
                            }
                            TableColumn("Value") { _ in
//                                Text(verbatim: "\(Amount.fromSat(fromSat: vin.previousOutput.value).displayBtc)")
                            }
                        } rows: {
                            ForEach(tx.input(), id: \.id) { tx in
                                TableRow(tx)
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
                            ForEach(esTx.vout) { tx in
                                TableRow(tx)
                            }
                        }
                    }
                    .frame(minHeight: 218)
                }

                Section {
                    LabeledContent("Vsize") {
                        Text(verbatim: "\(tx.vsize()) kvB")
                    }
                    LabeledContent("Size") {
                        Text(verbatim: "\(tx.totalSize()) kB")
                    }
                    LabeledContent("Version") {
                        Text(verbatim: "\(tx.version())")
                    }
                    LabeledContent("Weight") {
                        Text(verbatim: "\(tx.weight()) kWu")
                    }
                    LabeledContent("LockTime") {
                        Text(verbatim: "\(tx.lockTime())")
                    }
                }
            }
            .formStyle(.grouped)
            VStack {
                HStack {
                    Spacer()
                    Button {
                        do {
                            let (ok, psbt) = try walletVm.sign(txBuilder)
                            if ok{
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
    }
}
