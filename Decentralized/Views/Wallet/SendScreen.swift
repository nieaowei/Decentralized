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

struct SendScreen: View {
    struct TxPsbt: Hashable {
        let tx: BitcoinDevKit.Transaction
        let psbt: Psbt
    }

    @Environment(WalletStore.self) var wallet: WalletStore
    @Environment(WssStore.self) var wss: WssStore
    @Environment(SyncClient.self) var syncClient: SyncClient
    @Environment(AppSettings.self) var settings: AppSettings
    @Environment(\.navigate) var navigate
    @Environment(\.showError) var showError

    @State var outputs: [Output] = []
    @State var selectedOutpoints = Set<String>()

    @Query var contacts: [Contact] = []
    @State var rate: Int = 0
    @State var enableRbf: Bool = true

    @State var showUtxosSelector: Bool = false

    @State var txBuilder: TxBuilder = .init()
    @State var psbt: Psbt? = nil
    @State var builtTx: TxPsbt? = nil

    var inputs: [SendUtxo] {
        return wallet.utxos.filter { lo in
            selectedOutpoints.contains(lo.id)
        }.map { lo in
            SendUtxo(lo: lo)
        }
    }

    var inputTotal: Amount {
        inputs.reduce(Amount.Zero) { partialResult, u in
            partialResult + Amount.fromSat(fromSat: u.txout.value)
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
                            withAnimation {
                                selectedOutpoints.removeAll()
                            }
                        } label: {
                            Image(systemName: "trash")
                            Text(verbatim: "Delete All")
                        }
                    }
                    .truncationMode(.middle)
//                    Text("Selected: \(inputTotal.displayBtc)")
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
                                    Button {
                                        withAnimation {
                                            outputs.removeAll { $0.id == o.id }
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                        Text(verbatim: "Delete")
                                    }
                                }
                        }
                    }
                    .truncationMode(.middle)
                    .contextMenu {
                        Button {
                            withAnimation {
                                outputs.append(Output(address: contacts.first?.addr ?? "", value: 0.001))
                            }
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
                }
                .padding(.all)
                .sheet(isPresented: $showUtxosSelector, content: {
                    VStack {
                        UtxoSelector(selected: $selectedOutpoints, utxos: wallet.utxos)
                        HStack {
                            Button {
                                showUtxosSelector = false
                            } label: {
                                Text(verbatim: "OK")
                                    .padding(.horizontal)
                            }
                            .controlSize(.large)
                            .buttonStyle(BorderedProminentButtonStyle())
                        }
                    }
                    .frame(minHeight: 300)
                    .padding(.all)
                })
                .onAppear {
                    rate = wss.fastFee
                }
            }
        }
        .navigationDestination(item: $builtTx) { txPsbt in
            SignScreen(tx: txPsbt.tx, psbt: txPsbt.psbt)
        }
    }

    func onBuild() {
        txBuilder = TxBuilder()

        for utxo in inputs {
            txBuilder = txBuilder.addUtxo(outpoint: utxo.outpoint)
        }

        for o in outputs {
            do {
                let script = try Address(address: o.address, network: settings.network.toBdkNetwork())
                    .scriptPubkey()
                txBuilder = try txBuilder.addRecipient(script: script, amount: Amount.fromBtc(fromBtc: o.value))
            } catch let error as AddressParseError {
                showError(error, "")
            } catch let error as ParseAmountError {
                showError(error, "")
            } catch {
                showError(error, "")
            }
        }

        txBuilder = txBuilder.enableRbf()

        do {
            txBuilder = try txBuilder.feeRate(feeRate: FeeRate.fromSatPerVb(satPerVb: UInt64(rate)))
            txBuilder = txBuilder.drainTo(script: wallet.payAddress!.scriptPubkey())

            let (tx, psbt) = try wallet.buildTx(txBuilder)
            builtTx = TxPsbt(tx: tx, psbt: psbt)

        } catch let error as FeeRateError {
            showError(error, "Invalid fee rate")
        } catch let error as CreateTxError {
            showError(error, "Create tranactions error")
        } catch {
            showError(error, "")
        }
    }

    func onDeleteUtxo(_ id: String) {
        selectedOutpoints.remove(id)
    }

    func onDeleteAllUtxo() {
        selectedOutpoints.removeAll()
    }
}

struct SignScreen: View {
    @Environment(WalletStore.self) var wallet: WalletStore
    @Environment(WssStore.self) var wss: WssStore
    @Environment(\.showError) var showError

    @Environment(\.dismiss) var dismiss

    let tx: BitcoinDevKit.Transaction

    let psbt: Psbt

    @State
    var showSuccess: Bool = false

    @State
    var loading: Bool = false

    var body: some View {
        VStack {
            ScrollView {
                TransactionDetailView(tx: wallet.createWalletTx(tx: tx))
            }
            HStack {
                Spacer()
                Button {
                    onSign()
                } label: {
                    Text("Sign")
                        .padding(.horizontal)
                }
                .primary()
            }
            .padding(.all)
        }
        .sheet(isPresented: $loading) {
            ProgressView()
        }
        .sheet(isPresented: $showSuccess) {
            VStack {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle")
                        .resizable()
                        .frame(width: 64, height: 64)
                        .foregroundStyle(.green)
                    Text("Payment Sent")
                        .font(.title2)
                    Text("Your transaction has been successfully sent")
                        .font(.footnote)
                    Button {
                        dismiss()
                        showSuccess = false
                    } label: {
                        Text("OK").padding(.horizontal)
                    }
                    .primary()
                }
            }
            .padding(.all)
        }
        .navigationTitle("Send Transaction Detail")

    }

    func onSign() {
        loading = true

        Task {
            do {
                let psbt = try wallet.sign(psbt)

                let tx = try psbt.extractTx()
                wss.subscribe([.transaction(tx.id)])

                let _ = try self.wallet.broadcast(tx)
                self.wallet.load()
                try await Task.sleep(nanoseconds: 1500000000)
                self.loading = false
                self.showSuccess = true

            } catch let error as CreateTxError {
                showError(error, "")
                self.loading = false
            } catch {
                showError(error, "")
                self.loading = false
            }
        }
    }
}

#Preview {
//    SendView(walletVm: .init(global: .live))
}
