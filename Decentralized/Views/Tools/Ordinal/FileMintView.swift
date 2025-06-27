//
//  FileMintView.swift
//  Decentralized
//
//  Created by Nekilc on 2025/6/16.
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
                GlassButton.primary("Build", action: onBuild)
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

            let r = await mintOrd(network: settings.network, utxos: utxos, file: NamedFile(name: fileName, data: fileData), payAddress: wallet.payAddress!.description, toAddr: reciver, feeRate: feeRate, postage: nil)
            switch r {
                case .success(let success):
                    mintPair = OrdinalMintPair(commitPsbt: success.commitPsbtTx, revealTx: success.revealTx)

                case .failure(let failure):
                    showError(failure, "Check params")
            }
//            let r = try! await mint(network: settings.network, utxos: utxos, file: NamedFile(name: "brc20.json", data: jsonData), payAddress: wallet.payAddress!.description, toAddr: reciver, feeRate: feeRate, postage: nil)
//            commitPsbt = r.commitPsbtTx
//            revealTx = r.revealTx
        }
    }
}
