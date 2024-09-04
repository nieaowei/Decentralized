//
//  Utxos.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/23.
//

import BitcoinDevKit
import SwiftUI

struct UtxosView: View {
    @Environment(WalletStore.self) var wallet: WalletStore

    @State var selected: Set<String> = .init()
    @State private var sortOrder = [KeyPathComparator(\LocalOutput.txout.value, order: .reverse)]

    var body: some View {
        VStack {
            Table(wallet.utxos, selection: $selected, sortOrder: $sortOrder) {
                TableColumn("OutPoint") { utxo in
                    Text(verbatim: "\(utxo.id)")
                        .truncationMode(.middle)
                }
                TableColumn("Value", value: \.diplayBTCValue)
            }
            .onChange(of: sortOrder, initial: true) { _, sortOrder in
                wallet.utxos.sort(using: sortOrder)
            }
            HStack {
                Spacer()
                Button(action: {
//                    wallet.global.tabIndex = .wallet(.send(selected: selected))
                }, label: {
                    Text("Send")
                        .padding(.horizontal)
                })
                .controlSize(.large)
                .buttonStyle(BorderedProminentButtonStyle())
            }
            .padding(.all)
        }
    }
}

// #Preview {
//    UtxosView(selected: .constant(Set<String>()), walletVm: .init(global: .init()))
// }
