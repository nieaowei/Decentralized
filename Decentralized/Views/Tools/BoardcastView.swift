//
//  BoardcastView.swift
//  Decentralized
//
//  Created by Nekilc on 2024/7/19.
//

import DecentralizedFFI
import SwiftUI

struct BroadcastView: View {
    @Environment(WalletStore.self) var wallet
    @Environment(\.showError) var showError
    @Environment(SyncClient.self) var syncClient

    @State var sigedHex: String = ""
    @State var showTxid: String? = nil
    @State var tx: WalletTransaction? = nil

    @State var errorMsg: String? = nil

    var body: some View {
        VStack {
            TextEditor(text: $sigedHex)
                .textEditorStyle(.automatic)
                .contentMargins(10, for: .scrollContent)
            HStack {
                Spacer()
                Button {
                    onBroadcast()
                } label: {
                    Text("Broadcast")
                }
                .primary()
//                    .navigationDestination(item: $tx) { tx in
//                        SendDetailView( tx: tx, txBuilder: .constant(.init()))
//                    }
            }
            .padding(.all)
        }
        .navigationDestination(item: $tx) { tx in
            TransactionDetailView(tx: tx)
        }
    }

    func onExtract() {
        guard case let .success(tx) = DecentralizedFFI.Transaction.fromData(data: Data(sigedHex.hexStringToByteArray())) else {
            showError(nil, "Invalid Transaction Hex")
            return
        }
        self.tx = wallet.createWalletTx(tx: tx)
        print(tx.id)
    }

    func onBroadcast() {
        guard case let .success(tx) = DecentralizedFFI.Transaction.fromData(data: Data(sigedHex.hexStringToByteArray())) else {
            showError(nil, "Invalid Transaction Hex")
            return
        }
        try! syncClient.broadcast(tx)
    }
}

#Preview {
    BroadcastView()
}
