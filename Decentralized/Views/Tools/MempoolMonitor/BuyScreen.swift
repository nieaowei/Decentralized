//
//  SnipeScreen.swift
//  Decentralized
//
//  Created by Nekilc on 2024/10/14.
//
import DecentralizedFFI
import SwiftUI

struct BuyScreen: View {
    enum BuyType {
        case rune, inscription
    }

    struct OrdinalRow: Identifiable {
        enum Status: Equatable {
            case loading
            case available
            case notAvailable
        }

        var id: String {
            inner.outpoint
        }

        let inner: MempoolOrdinal
        var status: Status = .loading
    }

    struct SummaryRow: Identifiable {
        var id: String {
            name
        }

        var name: String
        var amount: Double
        var value: UInt64

        var avgSat: Double {
            Double(value) / amount
        }
    }

    @Environment(EsploraClientWrap.self) var eslpora
    @Environment(WalletStore.self) var wallet
    @Environment(WssStore.self) var wss
    @Environment(AppSettings.self) var settings
    @Environment(\.modelContext) var ctx
    @Environment(\.showError) var showError

    let type: BuyType

    @MainActor
    @State
    var ordinals: [OrdinalRow]

    @State var buyFeeRate: UInt64 = 0
    @State var splitFeeRate: UInt64 = 0
    @State var fee: UInt64 = 0

    @State var recvAddress: String = ""

    @State var minFee: UInt64 = 0
    @State var minFeeRate: UInt64 = 0

    @State var summaryTable: [String: SummaryRow] = [:]

    init(type: BuyScreen.BuyType, ordinals: [MempoolOrdinal]) {
        self.type = type
        _ordinals = State(wrappedValue: ordinals.map { e in OrdinalRow(inner: e) })
    }

    @State var loading: Bool = true
    @State var buildLoading: Bool = false

    var isBuildable: Bool {
        totalSat != 0 && wallet.balance.total.toSat() > totalSat
    }

    @MainActor
    @State
    var totalSat: UInt64 = 0

    @State var psbts: [SignScreen.UnsignedPsbt]?

    var buildText: String {
        if isBuildable {
            "Build"
        } else {
            if wallet.balance.total.toSat() < totalSat {
                "Insufficient Balance"
            } else {
                "No Available Ordinal"
            }
        }
    }

    var body: some View {
        HSplitView {
            VStack {
                VSplitView {
                    Table(of: OrdinalRow.self) {
                        TableColumn("Name") { ordinal in
                            HStack {
                                switch ordinal.status {
                                case .available:
                                    Image(systemName: "checkmark.circle").foregroundStyle(.green)
                                case .notAvailable:
                                    Image(systemName: "xmark.circle").foregroundStyle(.red)
                                case .loading:
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                Text(ordinal.inner.displayName)
                                    .truncationMode(.middle)
                            }
                        }
                        TableColumn("Amount", value: \.inner.amountWithDiv.description)
                        TableColumn("Value") { ordinal in
                            Text("\(ordinal.inner.value.formattedSatoshis()) BTC")
                        }
                    } rows: {
                        ForEach(ordinals.shuffled()) { ordinal in
                            TableRow(ordinal)
                        }
                    }
                    VStack {
                        Form {
                            if loading {
                                HStack(alignment: .center) {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                            } else {
                                LabeledContent("Minimum Fee", value: minFee.description)
                                LabeledContent("Minimum Fee Rate", value: minFeeRate.description)
                            }
                        }
                        .formStyle(.grouped)
                    }
                }
            }
            VStack {
                VSplitView {
                    Table(summaryTable.map { (_: String, value: SummaryRow) in
                        value
                    }) {
                        TableColumn("Name", value: \.name)
                        TableColumn("Amount", value: \.amount.description)
                        TableColumn("Value") { s in

                            Text("\(s.value.formattedSatoshis()) (\(s.avgSat.displaySatsUnit))")
                        }
                    }
                    VStack {
                        Form {
                            HStack(alignment: .center) {
                                Spacer()
                                Text("\(totalSat.formattedSatoshis()) BTC")
                                    .font(.largeTitle)
                                Spacer()
                            }

                            TextField("Minimum Fee", value: $fee, formatter: NumberFormatter())
                            TextField("Minimum Buy Fee Rate", value: $buyFeeRate, formatter: NumberFormatter())
                            TextField("Split Fee Rate", value: $splitFeeRate, formatter: NumberFormatter())
                            TextField("Recive Address", text: $recvAddress)
                        }
                        .formStyle(.grouped)
                        HStack {
                            PrimaryButton(action: { Task(operation: onBuild) }) {
                                if !loading {
                                    Text(buildText).padding(.horizontal)
                                } else {
                                    ProgressView()
                                }
                            }
                            .disabled(loading || !isBuildable)
                        }
                        .padding(.all)
                    }
                }
            }
        }
        .navigationTitle("Buy")
        .toolbar {
            WalletStatusToolbar()
        }
        .onAppear(perform: onAppear)
        .task {
            await fetchOutPoints()
        }
        .navigationDestination(item: $psbts) { psbts in
            SignScreen(unsignedPsbts: psbts)
        }
        .sheet(isPresented: $buildLoading) {
            VStack {
                ProgressView()
                    .controlSize(.extraLarge)
            }
        }
    }

    func onAppear() {
        recvAddress = wallet.ordiAddress?.description ?? ""
        splitFeeRate = wss.fastFee
    }

    /*
     - fetch ordinal outpoint status
     - fallback check rune id
     - summary total fee, average fee etc.
     */
    func fetchOutPoints() async {
        var txCache: [String: Tx] = [:]
        var fees: [UInt64] = []
        var feeRates: [UInt64] = []
        var total: UInt64 = 0
        for (index, o) in ordinals.enumerated() {
            o.inner.isUsed = true

            let output = await eslpora
                .getOutputStatus(txid: o.inner.txid, index: UInt64(o.inner.vout))
                .inspectErrorAsync { error in
                    logger.error("getOutputStatus error: \(error)")
                }

            guard case let .success(output) = output else {
                return
            }
            if !output.spent { // maby spent == true is avaliable
                withAnimation {
                    ordinals[index].status = .notAvailable
                }
                continue
            }

            guard let status = output.status, !status.confirmed else {
                withAnimation {
                    ordinals[index].status = .notAvailable
                }
                continue
            }

            guard let txid = output.txid else {
                withAnimation {
                    ordinals[index].status = .notAvailable
                }
                continue
            }

            var tx = txCache[txid]

            if tx == nil {
                let remoteTx = await eslpora.getTxInfo(txid: txid)
                    .inspectErrorAsync { error in
                        logger.error("getTxInfo error: \(error)")
                    }
                guard case let .success(remoteTx) = remoteTx else {
                    return
                }
                tx = remoteTx
                txCache[txid] = tx
            }

            guard let tx else {
                withAnimation {
                    ordinals[index].status = .notAvailable
                }
                continue
            }

            fees.append(tx.fee.toSat())
            feeRates.append(tx.feeRate)
            total += o.inner.value

            if type == .rune && o.inner.ordinalId.isEmpty { // fallback runeid
                guard case var .success(runeid) = fetchRuneIdFromDB(modelCtx: ctx, name: o.inner.name) else {
                    return
                }

                if runeid == nil {
                    guard case let .success(remoteRuneId) = await fetchRuneIdFromUrl(
                        url: settings.runefallbackUrl,
                        auth: settings.runefallbackAuth,
                        txid: o.inner.txid,
                        vout: o.inner.vout.description,
                        idPath: settings.runefallbackIdPath
                    ).inspectError({ err in
                        logger.error("fetchRuneIdFromUrl error: \(err)")
                    }) else {
                        return
                    }
                    if let remoteRuneId {
                        _ = ctx.upsert(RuneInfo(id: remoteRuneId, name: o.inner.name))
                        runeid = remoteRuneId
                    }
                }
                guard let runeid else {
                    withAnimation {
                        ordinals[index].status = .notAvailable
                    }
                    continue
                }
                ordinals[index].inner.ordinalId = runeid
            }

            withAnimation {
                if !o.inner.name.isEmpty {
                    if let _ = summaryTable[o.inner.name] {
                        summaryTable[o.inner.name]?.amount += o.inner.amountWithDiv
                        summaryTable[o.inner.name]?.value += o.inner.value
                    } else {
                        summaryTable[o.inner.name] = SummaryRow(name: o.inner.name, amount: o.inner.amountWithDiv, value: o.inner.value)
                    }
                } else {
                    if let _ = summaryTable[o.inner.ordinalId] {
                        summaryTable[o.inner.ordinalId]?.amount += o.inner.amountWithDiv
                        summaryTable[o.inner.ordinalId]?.value += o.inner.value
                    } else {
                        summaryTable[o.inner.ordinalId] = SummaryRow(name: o.inner.ordinalId, amount: o.inner.amountWithDiv, value: o.inner.value)
                    }
                }
                ordinals[index].status = .available
            }
        }

        withAnimation {
            minFee = (fees.max() ?? 0) + 1000
            minFeeRate = (feeRates.max() ?? 0) + 1
            fee = minFee
            buyFeeRate = minFeeRate
            loading = false
            totalSat = total

            if summaryTable.count == 1 {
                if let name = summaryTable.first?.key {
                    summaryTable[name]?.value = total + minFee
                }
            }
        }
    }

    func validate() -> Bool {
        if fee < minFee {
            showError(nil, "Fee must be > \(minFee)")
            fee = minFee
            return false
        }
        if buyFeeRate < minFeeRate {
            showError(nil, "Buy fee rate must be > \(minFeeRate)")
            buyFeeRate = minFeeRate
            return false
        }
        return true
    }

    /*
     - check all params
     - fetch prevouts that is avaliable ordinal
     - goto sign screen
     */
    func onBuild() async {
        if !validate() {
            return
        }
        withAnimation {
            buildLoading = true
        }

        defer {
            withAnimation {
                buildLoading = false
            }
        }

        var snipeUtxoPairs: [SnipeRuneUtxoPair] = []
        var snipeInscriptions: [SnipeInscriptionPair] = []

        for o in ordinals where o.status == .available {
            let txin = newTxinFromHex(hex: o.inner.txinHex, witnessHex: o.inner.witnessHex)
            let txout = newTxoutFromHex(hex: o.inner.txoutHex)

            if let txin, let txout {
                let tx = await eslpora.getTx(txid: txin.previousOutput.txid.description)
                    .inspectError { error in
                        logger.error("[onBuild] getTx error: \(error)")
                        showError(error, "Fetch Remote Tx Error")
                    }
                guard case let .success(tx) = tx else {
                    return
                }
                if type == .rune {
                    let runeid = RuneId.fromString(string: o.inner.ordinalId)
                        .inspectError { error in
                            logger.error("[onBuild] runeId parse error: \(error)")
                            showError(error, "Invalid RuneId")
                        }
                    guard case let .success(runeid) = runeid else {
                        return
                    }

                    snipeUtxoPairs.append(SnipeRuneUtxoPair(txin: txin, prevout: tx.output()[Int(txin.previousOutput.vout)], txout: txout, runeId: runeid, amount: o.inner.amount))
                }
                if type == .inscription {
                    snipeInscriptions.append(SnipeInscriptionPair(txin: txin, prevout: tx.output()[Int(txin.previousOutput.vout)], txout: txout))
                }

                wallet.insertTxout(op: txin.previousOutput, txout: tx.output()[Int(txin.previousOutput.vout)])
            }
        }

        let recvAddress = Result {
            try Address(address: self.recvAddress, network: settings.network.toCustomNetwork())
        }.inspectError { error in
            logger.error("[onBuild] address parse error: \(error)")
            showError(error, "Invalid Recipient Address")
        }
        guard case let .success(recvAddress) = recvAddress else {
            return
        }

        let buyFeeRate = FeeRate.from(satPerVb: self.buyFeeRate)
            .inspectError { err in
                logger.error("[onBuild] buyFeeRate parse error: \(err)")
                showError(err, "Invalid Buy Fee Rate")
            }
        guard case let .success(buyFeeRate) = buyFeeRate else {
            return
        }

        let splitFeeRate = Result {
            try FeeRate.fromSatPerVb(satPerVb: self.splitFeeRate)
        }.inspectError { err in
            logger.error("[onBuild] splitFeeRate parse error: \(err)")
            showError(err, "Invalid Split Fee Rate")
        }
        guard case let .success(splitFeeRate) = splitFeeRate else {
            return
        }
        if type == .rune {
            let psbts = Decentralized.buildRuneSnipePsbt(
                cardinalUtxos: wallet.getUtxos().sorted(using: KeyPathComparator(\.txout.value, order: .reverse)),
                snipeUtxoPairs: snipeUtxoPairs,
                payAddr: wallet.payAddress!,
                ordiAddr: wallet.ordiAddress!,
                snipeMinFee: Amount.fromSat(sat: fee),
                snipeRate: buyFeeRate,
                splitRate: splitFeeRate,
                runeRecvAddr: recvAddress
            ).inspectError { error in
                logger.error("Build psbt error: \(error)")
                showError(error, "Build Psbt Error")
            }
            guard case let .success(psbts) = psbts else {
                return
            }

            self.psbts = [.init(psbt: psbts.snipe), .init(psbt: psbts.split, walletType: .ordinal)]
        }
        if type == .inscription {
            let psbts = Decentralized.buildInscriptionSnipePsbt(
                cardinalUtxos: wallet.getUtxos().sorted(using: KeyPathComparator(\.txout.value, order: .reverse)),
                dummyUtxos: wallet.getUtxos().filter { $0.txout.value.toSat() == 600 },
                snipeUtxoPairs: snipeInscriptions,
                payAddr: wallet.payAddress!,
                ordiAddr: wallet.ordiAddress!,
                snipeMinFee: Amount.fromSat(sat: fee),
                snipeRate: buyFeeRate,
                splitRate: splitFeeRate,
                inscriptionRecvAddr: recvAddress
            ).inspectError { error in
                logger.error("Build psbt error: \(error)")
                showError(error, "Build Psbt Error")
            }
            guard case let .success(psbts) = psbts else {
                return
            }

            self.psbts = [.init(psbt: psbts.snipe), .init(psbt: psbts.split, walletType: .ordinal)]
        }
    }
}

#Preview {
//    SnipeScreen()
}
