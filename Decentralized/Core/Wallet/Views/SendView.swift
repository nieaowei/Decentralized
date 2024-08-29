//
//  SendView.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/28.
//

import BitcoinDevKit
import SwiftData
import SwiftUI

struct Output: Identifiable {
    var id = UUID()
    var address: String
    var value: Double
}

struct SendUtxo: Identifiable {
    public var outpoint: OutPoint
    public var txout: TxOut
    public var isSpent: Bool
    public var deleteable: Bool = true
    public var id: String {
        "\(outpoint.txid):\(outpoint.vout)"
    }

    public var displayBtcValue: String {
        Amount.fromSat(fromSat: txout.value).displayBtc
    }

    init(lo: LocalOutput) {
        self.outpoint = lo.outpoint
        self.txout = lo.txout
        self.isSpent = lo.isSpent
    }
}

struct SendView: View {
    @Bindable var walletVm: WalletViewModel

    @State var output: [Output] = []

    @Query var contacts: [Contact] = []
    @State var rate: Int = 0
    @State var enableRbf: Bool = true

    @State var showUtxosSelector: Bool = false

    @State var selectedUtxos = Set<String>()
//    @State var utxos: [SendUtxo] = []
    var utxos: [SendUtxo] {
       
        return walletVm.utxos.filter { lo in
            selectedUtxos.contains(lo.id)
        }.map { lo in
            SendUtxo(lo: lo)
        }
    }

    var body: some View {
        VStack {
            HSplitView {
                VStack {
                    Table(of: SendUtxo.self) {
                        TableColumn("OutPoint") { utxo in
                            Text(utxo.id).truncationMode(.middle)
                        }
                        TableColumn("Value", value: \.displayBtcValue)
                    } rows: {
                        ForEach(utxos) { o in
                            TableRow(o)
                                .contextMenu {
                                    if o.deleteable {
                                        Button(action: { onDeleteUtxo(o.id) }, label: {
                                            Image(systemName: "trash")
                                            Text(verbatim: "Delete")
                                        })
                                    }
                                }
                        }
                    }
                    .contextMenu(menuItems: {
                        Button(action: {
                            showUtxosSelector = true
                        }, label: {
                            Image(systemName: "plus")
                            Text(verbatim: "Add")
                        })
                    })
                    .truncationMode(.middle)
                }

                VStack {
                    Table(of: Binding<Output>.self) {
                        TableColumn("Address") { $o in
                            Picker("", selection: $o.address) {
                                ForEach(contacts) { contact in
                                    Text(verbatim: contact.addr)
                                        .truncationMode(.middle)
                                        .tag(contact.addr)
                                }
                            }
                            .truncationMode(.middle)
//                            TextField("", text: $o.address)
//                                .textFieldStyle(.roundedBorder)
//                                .textInputSuggestions(contacts, id: \.id) { c in
//                                    Text(c.addr)
//                                        .textInputCompletion(c.addr)
//                                }
                        }
                        TableColumn("Value") { $o in
                            HStack(spacing: 0) {
                                TextField("", value: $o.value, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                Spacer()
                                Text("BTC")
                                    .padding(.leading)
                            }
                        }
                    } rows: {
                        ForEach($output) { o in
                            TableRow(o)
                                .contextMenu {
                                    Button(action: {
                                        output.removeAll { o1 in
                                            o1.id == o.id
                                        }
                                    }, label: {
                                        Image(systemName: "trash")
                                        Text(verbatim: "Delete")
                                    })
                                }
                        }
                    }
                    .truncationMode(.middle)
                    .contextMenu(menuItems: {
                        Button(action: {
                            output.append(Output(address: contacts.first?.addr ?? "", value: 0.0))
                        }, label: {
                            Image(systemName: "plus")
                            Text(verbatim: "Add")
                        })
                    })
                }
            }
            VStack {
                HStack(spacing: 18) {
                    Spacer()
                    Toggle("RBF", isOn: $enableRbf)
                    LabeledContent("Rate") {
                        TextField("Rate", value: $rate, format: .number)
                            .textFieldStyle(.roundedBorder)

                        Text("sats/vB")
                    }
                    .frame(width: 150)
                    Button(action: onSign, label: {
                        Text("Sign")
                            .padding(.horizontal)
                    })
                    .primary()
                }
            }
            .padding(.all)
        }
        .sheet(isPresented: $showUtxosSelector, onDismiss: {
            showUtxosSelector = false

        }, content: {
            VStack {
                UtxoSelector(selected: $selectedUtxos, utxos: walletVm.utxos)
                HStack {
                    Button {
                        showUtxosSelector = false
                        print(selectedUtxos)
//                        for su in selectedUtxos {
//                            if let f = walletVm.utxos.first(where: { u in
//                                u.id == su
//                            }) {
//                                if !utxos.contains(where: { u in
//                                    u.id == f.id
//                                }) {
//                                    utxos.append(SendUtxo(lo: f))
//                                }
//                            }
//                        }

                    } label: {
                        Text(verbatim: "Ok")
                            .padding(.horizontal)
                    }
                    .controlSize(.large)
                    .buttonStyle(BorderedProminentButtonStyle())
                }
            }
            .frame(minHeight: 300)
            .padding(.all)
        })
        .onChange(of: walletVm.global.walletSyncState, initial: true) {
            walletVm.getUtxos()
        }
        .onAppear {
            rate = walletVm.global.wss.fastfee
        }
    }

    func onSign() {
//        BumpFeeTxBuilder(txid: "", feeRate: FeeRate.fromSatPerVb(satPerVb: 10))
        var tx = TxBuilder()
        if !utxos.isEmpty {
            for utxo in utxos {
                tx = tx.addUtxo(outpoint: utxo.outpoint)
            }
        }

        if !output.isEmpty {
            for o in output {
                do {
                    let script = try Address(address: o.address, network: .bitcoin)
                        .scriptPubkey()
                    tx = try tx.addRecipient(script: script, amount: Amount.fromBtc(fromBtc: o.value))
                } catch {
                    print(error)
                }
            }
        }
        do {
            tx = try tx.feeRate(feeRate: FeeRate.fromSatPerVb(satPerVb: UInt64(rate)))
//            tx = tx.changePolicy(changePolicy: .changeForbidden)

//            tx = try tx.addRecipient(script: walletVm.bdkClient.getPayAddress().scriptPubkey(), amount: Amount.fromBtc(fromBtc: o.value))
            tx = try tx.drainTo(script: walletVm.global.bdkClient.getPayAddress().scriptPubkey())
//            let changeAmount = try walletVm.global.bdkClient.getChangeAmount(tx)
            try walletVm.global.bdkClient.buildTxAndSign(tx)
//            print(changeAmount.displayBtc)
        } catch {
            print(error)
        }
    }

    func onDeleteUtxo(_ id: String) {
//        utxos.removeAll { o1 in
//            o1.id == id
//        }
        selectedUtxos.remove(id)
    }
}

#Preview {
    SendView(walletVm: .init(global: .live))
}
