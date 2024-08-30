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

    @State var outputs: [Output] = []
    @State var selectedOutpoints = Set<String>()

    @Query var contacts: [Contact] = []
    @State var rate: Int = 0
    @State var enableRbf: Bool = true

    @State var showUtxosSelector: Bool = false
    @State var gotoSendDetail: Bool = false

    @State var builtTx: BitcoinDevKit.Transaction? = nil
    @State var txBuilder: TxBuilder = .init()

    @State var showError: Bool = false
    @State var appError: AppError?

    var inputs: [SendUtxo] {
        return walletVm.utxos.filter { lo in
            selectedOutpoints.contains(lo.id)
        }.map { lo in
            SendUtxo(lo: lo)
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                HSplitView {
                    VStack {
                        Table(of: SendUtxo.self) {
                            TableColumn("OutPoint") { utxo in
                                Text(utxo.id).truncationMode(.middle)
                            }
                            TableColumn("Value", value: \.displayBtcValue)
                        } rows: {
                            ForEach(inputs) { o in
                                TableRow(o)
                                    .contextMenu {
                                        if o.deleteable {
                                            Button {
                                                onDeleteUtxo(o.id)
                                            } label: {
                                                Image(systemName: "trash")
                                                Text(verbatim: "Delete")
                                            }
                                        }
                                    }
                            }
                        }
                        .contextMenu {
                            Button {
                                showUtxosSelector = true
                            } label: {
                                Image(systemName: "plus")
                                Text(verbatim: "Add")
                            }
                            Button {
                                selectedOutpoints.removeAll()
                            } label: {
                                Image(systemName: "trash")
                                Text(verbatim: "Delete All")
                            }
                        }
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
                            ForEach($outputs) { o in
                                TableRow(o)
                                    .contextMenu {
                                        Button(action: {
                                            outputs.removeAll { o1 in
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
                        .contextMenu {
                            Button {
                                outputs.append(Output(address: contacts.first?.addr ?? "", value: 0.001))
                            } label: {
                                Image(systemName: "plus")
                                Text(verbatim: "Add")
                            }
                        }
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

                        Button(action: onBuild) {
                            Text("Build")
                                .padding(.horizontal)
                        }
                        .primary()
                        .navigationDestination(isPresented: $gotoSendDetail) {
                            if case let .some(builtTx) = builtTx {
                                SendDetailView(walletVm: walletVm, tx: builtTx, txBuilder: $txBuilder)
                            }
                        }
                    }
                }
                .padding(.all)
            }
            .sheet(isPresented: $showUtxosSelector, content: {
                VStack {
                    UtxoSelector(selected: $selectedOutpoints, utxos: walletVm.utxos)
                    HStack {
                        Button {
                            showUtxosSelector = false
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
            .alert(isPresented: $showError, error: appError, actions: {})
            .onChange(of: walletVm.global.walletSyncState, initial: true) {
                walletVm.getUtxos()
            }
            .onAppear {
                rate = walletVm.global.wss.fastfee
            }
        }
    }

    func onBuild() {

        if !inputs.isEmpty {
            for utxo in inputs {
                txBuilder = txBuilder.addUtxo(outpoint: utxo.outpoint)
            }
        }

        if !outputs.isEmpty {
            for o in outputs {
                do {
                    let script = try Address(address: o.address, network: .bitcoin)
                        .scriptPubkey()
                    txBuilder = try txBuilder.addRecipient(script: script, amount: Amount.fromBtc(fromBtc: o.value))
                } catch let error as AddressParseError {
                    print(error)
                } catch let error as ParseAmountError {
                    print(error)
                } catch {
                    print(error)
                }
            }
        }
        do {
            txBuilder = try txBuilder.feeRate(feeRate: FeeRate.fromSatPerVb(satPerVb: UInt64(rate)))
            txBuilder = try txBuilder.drainTo(script: walletVm.global.bdkClient.getPayAddress().scriptPubkey())
            builtTx = try walletVm.global.bdkClient.buildTx(txBuilder)

            gotoSendDetail = true
        } catch {
            showError = true
            appError = .generic(message: error.localizedDescription)
        }
    }

    func onDeleteUtxo(_ id: String) {
        selectedOutpoints.remove(id)
    }
}

#Preview {
    SendView(walletVm: .init(global: .live))
}
