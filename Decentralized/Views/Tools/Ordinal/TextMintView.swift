//
//  TextMintView.swift
//  Decentralized
//
//  Created by Nekilc on 2025/6/16.
//
import DecentralizedFFI
import SwiftUI

struct TextMintView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(WalletStore.self) private var wallet
    @Environment(WssStore.self) private var wss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.showError) private var showError
    @Environment(\.navigate) private var na

    @Binding var mintPair: OrdinalMintPair?

    @State var text: String = ""
    @State var reciver: String = ""
    @State var feeRate: UInt64 = 0

    @State var showContactSeletor = false
    @State private var selectedContact: Contact? = nil

    var body: some View {
        Form {
            Section("Text") {
                TextEditor(text: $text)
                    .frame(height: 100)
                    .font(.system(size: 15))
                    .textEditorStyle(.plain)
            }
            Section {
                HStack {
                    TextField("Reciver", text: $reciver)
                    Button("Select Contact") {
                        showContactSeletor = true
                    }
                    .sheet(isPresented: $showContactSeletor) {
                        ContactPicker { contact in
                            reciver = contact.addr
                        }
                        .frame(minHeight: 300)
                        .padding(.all)
                    }
                }
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
            let r = await mintOrd(network: settings.network, utxos: utxos, file: NamedFile(name: "text.txt", data: text.data(using: .utf8)!), payAddress: wallet.payAddress!.description, toAddr: reciver, feeRate: feeRate, postage: nil)
            switch r {
                case .success(let success):
                    mintPair = OrdinalMintPair(commitPsbt: success.commitPsbtTx, revealTx: success.revealTx)
                    
                case .failure(let failure):
                    showError(failure, "Check params")
            }
        }
    }
}
