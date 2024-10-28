//
//  SendView.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/28.
//

import DecentralizedFFI
import LocalAuthentication
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct Recipient: Identifiable, Transferable, Codable {
    var id: UUID = .init()
    var address: String
    var value: Double

    static var draggableType = UTType(exportedAs: "app.decentralized.Recipient")

    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: Self.draggableType)
    }
}

struct SendUtxo: Identifiable, Transferable, Codable {

    public var id: String {
        "\(outpoint.txid):\(outpoint.vout)"
    }

    public var outpoint: OutPoint
    public var txout: TxOut
    public var isSpent: Bool = true
    public var deleteable: Bool

    init(lo: LocalOutput, deleteable: Bool = true) {
        self.outpoint = lo.outpoint
        self.txout = lo.txout
        self.isSpent = lo.isSpent
        self.deleteable = deleteable
    }

    init(outpoint: OutPoint, txout: TxOut, deleteable: Bool = true) {
        self.outpoint = outpoint
        self.txout = txout
        self.deleteable = deleteable
    }
    static var draggableType = UTType(exportedAs: "app.decentralized.SendUtxo")

    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: Self.draggableType)
    }
}

struct SendScreen: View {
    struct TxPsbt: Hashable {
        let tx: DecentralizedFFI.Transaction
        let psbt: Psbt
    }

    var minFee: Amount = .Zero
    var isRBF: Bool = false
    var isCPFP: Bool = false

    @Environment(WalletStore.self) var wallet: WalletStore
    @Environment(WssStore.self) var wss: WssStore
    @Environment(SyncClient.self) var syncClient: SyncClient
    @Environment(AppSettings.self) var settings: AppSettings
    @Environment(\.navigate) var navigate
    @Environment(\.showError) var showError

    @State var outputs: [Recipient] = []
    @State var selectedOutpointIds = Set<String>()

//    @State var selectedOutpoints: [String] = []

    @Query var contacts: [Contact] = []
    @State var rate: UInt64 = 0
    @State var enableRbf: Bool = true

    @State var showUtxosSelector: Bool = false

    @State var builtPsbt: Psbt? = nil

    @State private var inputs: [SendUtxo] = []

    var inputTotal: Amount {
        inputs.reduce(Amount.Zero) { partialResult, u in
            partialResult + u.txout.value
        }
    }

    var outputTotal: Amount {
        outputs.reduce(Amount.Zero) { partialResult, o in
            partialResult + Amount.from(btc: o.value).unwrap()
        }
    }

    @State var fee: Amount = .Zero

    var enableMax: Bool {
        inputTotal.toSat() >= (outputTotal + fee).toSat() || inputs.isEmpty
    }

    var body: some View {
        VStack {
            HSplitView {
                VStack {
                    Table(of: SendUtxo.self) {
                        TableColumn("OutPoint") { utxo in
                            Text(utxo.id).truncationMode(.middle)
                        }
                        TableColumn("Value", value: \.txout.value.formatted)
                    } rows: {
                        ForEach(inputs) { o in
                            TableRow(o)
                                .draggable(o)
                                .contextMenu {
                                    if o.deleteable {
                                        Button { onRemoveUtxo(o.id) } label: {
                                            Image(systemName: "trash")
                                            Text(verbatim: "Delete")
                                        }
                                    }
                                }
                        }
                        .dropDestination(for: SendUtxo.self) { index, recipients in
                            guard let first = recipients.first, let firstRemoveIndex = self.inputs.firstIndex(where: { $0.id == first.id }) else { return }

                            self.inputs.removeAll(where: { pokemon in
                                recipients.contains(where: { insertPokemon in insertPokemon.id == pokemon.id })
                            })

                            self.inputs.insert(contentsOf: recipients, at: index > firstRemoveIndex ? (index - 1) : index)
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
                            Text(verbatim: "Remove All")
                        }
                    }
                    .truncationMode(.middle)
                }
                // Output
                VStack {
                    Table(of: Binding<Recipient>.self) {
                        TableColumn("Address") { $o in
                            HStack(spacing: 0) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .draggable(o)
                                Picker("", selection: $o.address) {
                                    ForEach(contacts) { contact in
                                        Text(verbatim: "\(contact.name):\(contact.addr)")
                                            .tag(contact.addr)
                                            .truncationMode(.middle)
                                    }
                                }
                            }
                        }
                        TableColumn("Value") { $o in
                            HStack(spacing: 0) {
                                TextField("", value: $o.value, format: .number.precision(.fractionLength(8)))
                                    .textFieldStyle(.roundedBorder)
                                Text("BTC")
                                    .padding(.leading)
                                Spacer()
                                Button("Max", action: { onMax(o) })
                                    .disabled(!enableMax)
                            }
                        }
                    } rows: {
                        ForEach($outputs) { $o in
                            TableRow($o)
                                .contextMenu {
                                    Button {
                                        onRemoveOutput(o.id)
                                    } label: {
                                        Image(systemName: "trash")
                                        Text(verbatim: "Remove")
                                    }
                                }
                        }
                        .dropDestination(for: Recipient.self) { index, recipients in
                            guard let first = recipients.first, let firstRemoveIndex = self.outputs.firstIndex(where: { $0.id == first.id }) else { return }

                            self.outputs.removeAll(where: { pokemon in
                                recipients.contains(where: { insertPokemon in insertPokemon.id == pokemon.id })
                            })

                            self.outputs.insert(contentsOf: recipients, at: index > firstRemoveIndex ? (index - 1) : index)
                        }
                    }
                    .truncationMode(.middle)
                    .contextMenu {
                        Button {
                            onAddOutput()
                        } label: {
                            Image(systemName: "plus")
                            Text(verbatim: "Add")
                        }
                        Button {
                            onRemoveAllOutput()
                        } label: {
                            Image(systemName: "trash")
                            Text(verbatim: "Remove All")
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
                        UtxoSelector(selected: $selectedOutpointIds, utxos: wallet.utxos)
                        HStack {
                            PrimaryButton("OK") {
                                let added = selectedOutpointIds.reduce(into: [SendUtxo]()) { partialResult, id in
                                    if let lo = wallet.allUtxos.first(where: { $0.id == id }), !inputs.contains(where: {$0.id == lo.id}) {
                                        partialResult.append(SendUtxo(lo: lo))
                                    }
                                }
                                withAnimation {
                                    inputs.append(contentsOf: added)
                                    showUtxosSelector = false
                                }
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
        .navigationDestination(item: $builtPsbt) { psbt in
            SignScreen(unsignedPsbts: [.init(psbt: psbt)])
        }
    }

    func build(_ change: Recipient) -> Result<Psbt, Error> {
        var txBuilder = TxBuilder()
        txBuilder = txBuilder.ordering(txOrdering: TxOrdering.untouched)

        for utxo in inputs {
            txBuilder = txBuilder.addUtxo(outpoint: utxo.outpoint)
        }

        // receiver
        let settedChange = outputs.reduce(into: false) { settedChange, o in
            if o.id == change.id {
                settedChange = true
                return
            }
            guard case .success(let addr) = Address.from(address: o.address, network: settings.network.toBitcoinNetwork()) else {
                showError(nil, "\(o.address) is invalid")
                return
            }
            guard case .success(let amount) = Amount.from(btc: o.value) else {
                showError(nil, "\(o.value) is invalid")
                return
            }

            txBuilder = txBuilder.addRecipient(script: addr.scriptPubkey(), amount: amount)
        }

        // all utxo to change
        if settedChange && inputs.isEmpty {
            for u in wallet.utxos {
                txBuilder = txBuilder.addUtxo(outpoint: u.outpoint)
            }
        }

        let feeRate = FeeRate.from(satPerVb: UInt64(rate))

        guard case .success(let feeRate) = feeRate else {
            return .failure(feeRate.err()!)
        }

        txBuilder = txBuilder.feeRate(feeRate: feeRate)

        let changeAddr = Address.from(address: change.address, network: settings.network.toBitcoinNetwork())

        guard case .success(let changeAddr) = changeAddr else {
            return .failure(changeAddr.err()!)
        }

        txBuilder = txBuilder.drainTo(script: changeAddr.scriptPubkey())

        let psbt = wallet.finish(txBuilder)

        guard case .success(let psbt) = psbt else {
            return .failure(psbt.err()!)
        }

        return .success(psbt)
    }

    func onMax(_ o: Recipient) {
        let psbt = build(o)
        guard case .success(let psbt) = psbt else { return }
        let tx = psbt.extractTxUncheckedFeeRate()

        outputs = tx.output().map { txout in
            Recipient(address: txout.formattedScript(network: settings.network.toBitcoinNetwork()), value: txout.value.toBtc())
        }
        for txin in tx.input() {
            if !inputs.contains(where: { $0.id == txin.id }) {
                if let lo = wallet.allUtxos.first(where: { $0.id == txin.id }) {
                    withAnimation {
                        inputs.append(SendUtxo(lo: lo))
                    }
                   
                }
            }
        }
        let _ = Result {
            try psbt.fee()
        }.map { amount in
            fee = amount
        }
    }

    func onBuild() {
        let _ = build(Recipient(address: wallet.payAddress!.description, value: 0)).inspect { psbt in
            withAnimation {
                builtPsbt = psbt
            }
        }
    }

    func onRemoveUtxo(_ id: String) {
        withAnimation {
            inputs.removeAll { i in
                i.id == id
            }
        }
    }

    func onRemoveAllUtxo() {
        withAnimation {
            inputs.removeAll()
        }
    }

    func onAddOutput() {
        withAnimation {
            outputs.append(Recipient(address: contacts.first?.addr ?? "", value: 0.001))
        }
    }

    func onRemoveOutput(_ id: UUID) {
        withAnimation {
            outputs.removeAll { $0.id == id }
        }
    }

    func onRemoveAllOutput() {
        withAnimation {
            outputs.removeAll()
        }
       
    }
}

#Preview {
//    SendView(walletVm: .init(global: .live))
}
