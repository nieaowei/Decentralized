//
//  CustomBuyAddView.swift
//  Decentralized
//
//  Created by Nekilc on 2024/10/21.
//

import DecentralizedFFI
import SwiftUI

struct CustomBuyAddView: View {
    @Environment(Esplora.self) var esplora
    @Environment(AppSettings.self) var settings
    @Environment(\.modelContext) var ctx
    @Environment(\.showError) var showError

    @State var txid: String = ""

    @Binding var isPresented: Bool

    @State var loading: Bool = false
    @State var success: Bool = false

    var body: some View {
        VStack {
            if !loading {
                if !success {
                    Form {
                        Section {
                            TextField("Txid", text: $txid)
                        }
                        .sectionActions {
                            GlassButton.primary("Confirm", action: onConfirm)
                            GlassButton.cancel("Cancel") {
                                isPresented = false
                            }
                        }
                    }
                    .formStyle(.grouped)
                } else {
                    VStack {
                        Image(systemName: "checkmark.circle")
                            .resizable()
                            .frame(width: 64, height: 64)
                            .foregroundStyle(.green)
                        PrimaryButton("OK") {
                            withAnimation {
                                isPresented = false
                            }
                        }
                    }
                    .padding(.all)
                }
            } else {
                ProgressView()
            }
        }
    }

    func onConfirm() {
        Task {
            withAnimation {
                loading = true
            }
            defer {
                withAnimation {
                    loading = false
                }
            }

            guard case .success(let txid) = Txid.from(hex: txid) else {
                showError(nil, "Invalid Txid")
                return
            }

            guard case .success(let tx) = await esplora.getWrap().getTxInfo(txid: txid).inspectError({ error in
                logger.error("Error fetching tx info: \(error)")
                showError(error, "Error fetching tx info")
            }) else {
                return
            }
            guard case .success(let pairs) = await fetchOrdinalTxPairsAsync(esploraClient: esplora.getWrap(), settings: settings.storage, esploraWssTx: EsploraWssTx(txid: tx.txid.description, flags: 0, feeRate: Double(tx.feeRate))).inspectError({ error in
                logger.error("Error fetching ordinal: \(error)")
                showError(error, "Error fetching ordinal")
            }) else {
                return
            }
            for pair in pairs {
                _ = ctx.upsert(pair)
            }
            withAnimation {
                success = true
            }
        }
    }
}
