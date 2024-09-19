//
//  SendView.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/28.
//

import BitcoinDevKit
import LocalAuthentication
import SwiftData
import SwiftUI

struct SendScreen: View {
    struct Output: Identifiable {
        var id = UUID()
        var address: String
        var value: Double
    }

    struct Utxo: Identifiable {
        public var id: String {
            "\(outpoint.txid):\(outpoint.vout)"
        }

        public var outpoint: OutPoint
        public var txout: TxOut
        public var isSpent: Bool = true
        public var deleteable: Bool = true

        public var displayBtcValue: String {
            Amount.fromSat(fromSat: txout.value).displayBtc
        }

        init(lo: LocalOutput) {
            self.outpoint = lo.outpoint
            self.txout = lo.txout
            self.isSpent = lo.isSpent
        }

        init(outpoint: OutPoint, txout: TxOut) {
            self.outpoint = outpoint
            self.txout = txout
        }
    }

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

//    @State var psbt: Psbt? = nil
    @State var builtTx: TxPsbt? = nil

    var inputs: [Utxo] {
        wallet.utxos.reduce(into: [Utxo]()) { partialResult, lo in
            if selectedOutpoints.contains(lo.id) {
                partialResult.append(Utxo(lo: lo))
            }
        }
    }

    var inputTotal: Amount {
        inputs.reduce(Amount.Zero) { partialResult, u in
            partialResult + Amount.fromSat(fromSat: u.txout.value)
        }
    }

    var outputTotal: Amount {
        outputs.reduce(Amount.Zero) { partialResult, o in
            partialResult + (try! Amount.fromBtc(fromBtc: o.value))
        }
    }
    
    @State var fee: Amount = .Zero


    var body: some View {
        VStack {
            HSplitView {
                VStack {
                    Table(of: Utxo.self) {
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
                                            onRemoveUtxo(o.id)
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
                        Button(action: onRemoveAllUtxo) {
                            Image(systemName: "trash")
                            Text(verbatim: "Delete All")
                        }
                    }
                    .truncationMode(.middle)
                }
                // Output
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
                                TextField("", value: $o.value, format: .number.precision(.fractionLength(8)))
                                    .textFieldStyle(.roundedBorder)
                                Text("BTC")
                                    .padding(.leading)
                                Spacer()
                                Button("Max", action: { onMax(o) })
                                    .disabled(inputTotal.toSat() <= (outputTotal + fee).toSat())
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
                    PrimaryButton("Build", action: onBuild)
                }
                .padding(.all)
                .sheet(isPresented: $showUtxosSelector, content: {
                    VStack {
                        UtxoSelector(selected: $selectedOutpoints, utxos: wallet.utxos)
                        HStack {
                            PrimaryButton("OK") {
                                showUtxosSelector = false
                            }
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

    func build(_ change: Output) throws -> TxPsbt {
        var txBuilder = TxBuilder()

        for utxo in inputs {
            txBuilder = txBuilder.addUtxo(outpoint: utxo.outpoint)
        }

        // setting receiver
        let settedChange = outputs.reduce(into: false) { settedChange, o in
            if o.id == change.id {
                settedChange = true
                return
            }
            do {
                let script = try Address(address: o.address, network: settings.network.toBdkNetwork()).scriptPubkey()
                txBuilder = try txBuilder.addRecipient(script: script, amount: Amount.fromBtc(fromBtc: o.value))
            } catch let error as AddressParseError {
                showError(error, "\(o.address) is invalid")
            } catch let error as ParseAmountError {
                showError(error, "")
            } catch {
                showError(error, "")
            }
        }

        // all utxo to change
        if settedChange && inputs.isEmpty {
            for u in wallet.utxos {
                txBuilder = txBuilder.addUtxo(outpoint: u.outpoint)
            }
        }

        txBuilder = txBuilder.enableRbf()
        txBuilder = try txBuilder.feeRate(feeRate: FeeRate.fromSatPerVb(satPerVb: UInt64(rate)))

        txBuilder = try txBuilder.drainTo(script: Address(address: change.address, network: settings.network.toBdkNetwork()).scriptPubkey())

        let (tx, psbt) = try wallet.buildTx(txBuilder)

        return TxPsbt(tx: tx, psbt: psbt)
    }

    func onMax(_ o: Output) {
        do {
            let psbt = try build(o)
            outputs = psbt.tx.output().map { txout in
                Output(address: try! txout.address(network: settings.network.toBdkNetwork()), value: Amount.fromSat(fromSat: txout.value).toBtc())
            }
            for txin in psbt.tx.input() {
                selectedOutpoints.insert(txin.id)
            }
            fee = try Amount.fromSat(fromSat: psbt.psbt.fee())
        } catch {
            print(error)
        }
    }

    func onBuild() {
        do {
            builtTx = try build(Output(address: wallet.payAddress!.description, value: 0))
        } catch let error as FeeRateError {
            showError(error, "Invalid fee rate")
        } catch let error as CreateTxError {
            showError(error, "Create transaction error")
        } catch {
            showError(error, "Create transaction error")
        }
    }

    func onRemoveUtxo(_ id: String) {
        selectedOutpoints.remove(id)
    }

    func onRemoveAllUtxo() {
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
                PrimaryButton("Sign", action: onSign)
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
                    PrimaryButton("OK") {
                        dismiss()
                        showSuccess = false
                    }
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
