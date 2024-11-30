//
//  OrdinalMintScreen.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/24.
//

import DecentralizedFFI
import QuickLook
import QuickLookUI
import SwiftUI

struct FilePreview: NSViewRepresentable {
    let fileURL: URL

    func makeNSView(context: Context) -> QLPreviewView {
        let previewView = QLPreviewView(frame: NSRect.zero, style: .normal)!
        previewView.previewItem = fileURL as QLPreviewItem
        return previewView
    }

    func updateNSView(_ nsView: QLPreviewView, context: Context) {
        nsView.previewItem = fileURL as QLPreviewItem
    }
}

struct OrdinalMintPair: Hashable {
    var commitPsbt: Psbt
    var revealTx: DecentralizedFFI.Transaction
}

struct OrdinalScreen: View {
    @Environment(AppSettings.self) private var settings
    @Environment(WalletStore.self) private var wallet

    @State var selection: String = "Text"

    @State var mintPair: OrdinalMintPair? = nil

    var body: some View {
        ScrollView {
            Picker("", selection: $selection) {
                Text("Text").tag("Text")
                Text("File").tag("File")
                Text("BRC20").tag("BRC20")
            }
            .pickerStyle(.palette)
            switch selection {
                case "Text":
                    TextMintView(mintPair: $mintPair)
                case "File":
                    FileMintView(mintPair: $mintPair)
                case "BRC20":
                    BRC20MintView(mintPair: $mintPair)
                default:
                    FileMintView(mintPair: $mintPair)
            }
        }
        .padding(.all)
        .toolbar {
            WalletStatusToolbar()
        }
        .navigationDestination(item: $mintPair) { psbt in
            SignScreen(unsignedPsbts: [SignScreen.UnsignedPsbt(psbt: psbt.commitPsbt)], deferBroadcastTxs: [psbt.revealTx])
        }
    }
}

struct TextMintView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(WalletStore.self) private var wallet
    @Environment(WssStore.self) private var wss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.showError) private var showError

    @Binding var mintPair: OrdinalMintPair?

    @State var text: String = ""
    @State var reciver: String = ""
    @State var feeRate: UInt64 = 0

    var body: some View {
        Form {
            Section("Text") {
                TextEditor(text: $text)
                    .frame(height: 100)
                    .font(.system(size: 15))
                    .textEditorStyle(.plain)
            }
            Section {
                TextField("Reciver", text: $reciver)
                TextField("Fee Rate", value: $feeRate, formatter: NumberFormatter())
            }
            .sectionActions {
                PrimaryButton("Build", action: onBuild)
            }
        }
        .formStyle(.grouped)
        .onAppear {
            reciver = wallet.ordiAddress?.description ?? ""
            feeRate = wss.fastFee
        }
    }

    func onBuild() {
        Task {
            if reciver.isEmpty {
                showError(nil, "Reciver is empty")
                return
            }
            if feeRate <= 1 {
                showError(nil, "Fee Rate must be > 1")
                return
            }
            if text.isEmpty {
                showError(nil, "Text is empty")
                return
            }
            let utxos = wallet.utxos.sorted { l, r in
                l.txout.value > r.txout.value
            }
            let r = await mintOrd(network: settings.network.toBitcoinNetwork(), utxos: utxos, file: NamedFile(name: "text.txt", data: text.data(using: .utf8)!), payAddress: wallet.payAddress!.description, toAddr: reciver, feeRate: feeRate, postage: nil)
            switch r {
                case .success(let success):
                    mintPair = OrdinalMintPair(commitPsbt: success.commitPsbtTx, revealTx: success.revealTx)

                case .failure(let failure):
                    showError(failure, "Check params")
            }
        }
    }
}

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
                PrimaryButton("Build", action: onConfirm)
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
            let r = await mintOrd(network: settings.network.toBitcoinNetwork(), utxos: utxos, file: NamedFile(name: "brc20.json", data: jsonData), payAddress: wallet.payAddress!.description, toAddr: reciver, feeRate: feeRate, postage: nil)
            switch r {
                case .success(let success):
                    mintPair = OrdinalMintPair(commitPsbt: success.commitPsbtTx, revealTx: success.revealTx)

                case .failure(let failure):
                    showError(failure, "Check params")
            }

//            let ordi = OrdinalHistory(commitTxId: r.commitPsbtTx.extractTx().computeTxid(), revealTxId: r.revealTx.computeTxid(), commitPsbtHex: r.commitPsbtTx.serializeHex(), revealTxHex: r.revealTx.description, revealPk: r.revealPrivateKey)
        }
    }
}

struct FileMintView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(WalletStore.self) private var wallet
    @Environment(WssStore.self) private var wss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.showError) private var showError

    @Binding var mintPair: OrdinalMintPair?

    @State var reciver: String = ""
    @State var feeRate: UInt64 = 0
    @State var showFilePicker: Bool = false
    @State var selectedFile: URL?

    var body: some View {
        if let selectedFile {
            FilePreview(fileURL: selectedFile)
                .frame(width: 200, height: 200)
        }
        Form {
            Section {
                LabeledContent("File") {
                    if let selectedFile {
                        Text(verbatim: selectedFile.standardizedFileURL.path(percentEncoded: false))
                    }
                    Button("Selecte File") {
                        showFilePicker = true
                    }
                }
                TextField("Reciver", text: $reciver)
                TextField("Fee Rate", value: $feeRate, formatter: NumberFormatter())
            }
            .sectionActions {
                PrimaryButton("Build", action: onBuild)
            }
        }
        .formStyle(.grouped)
        .onAppear {
            reciver = wallet.ordiAddress?.description ?? ""
            feeRate = wss.fastFee
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.image, .text, .audio, .video]) { result in
            if case .success(let file) = result {
                selectedFile = file
            }
        }
    }

    func onBuild() {
        Task {
            if reciver.isEmpty {
                showError(nil, "Reciver is empty")
                return
            }
            if feeRate <= 1 {
                showError(nil, "Fee Rate must be > 1")
                return
            }
            guard let selectedFile else {
                showError(nil, "Must be select a file")
                return
            }
            _ = wallet.utxos.sorted { l, r in
                l.txout.value > r.txout.value
            }

            let utxos = wallet.utxos.sorted { l, r in
                l.txout.value > r.txout.value
            }
            let fileName = selectedFile.lastPathComponent
            let fileData = try! Data(contentsOf: selectedFile)

            let r = await mintOrd(network: settings.network.toBitcoinNetwork(), utxos: utxos, file: NamedFile(name: fileName, data: fileData), payAddress: wallet.payAddress!.description, toAddr: reciver, feeRate: feeRate, postage: nil)
            switch r {
                case .success(let success):
                    mintPair = OrdinalMintPair(commitPsbt: success.commitPsbtTx, revealTx: success.revealTx)

                case .failure(let failure):
                    showError(failure, "Check params")
            }
//            let r = try! await mint(network: settings.network.toBitcoinNetwork(), utxos: utxos, file: NamedFile(name: "brc20.json", data: jsonData), payAddress: wallet.payAddress!.description, toAddr: reciver, feeRate: feeRate, postage: nil)
//            commitPsbt = r.commitPsbtTx
//            revealTx = r.revealTx
        }
    }
}

#Preview {
    OrdinalScreen()
}
