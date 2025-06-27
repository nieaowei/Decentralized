//
//  Utxos.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/23.
//

import DecentralizedFFI
import SwiftUI

struct UtxosView: View {
    @Environment(WalletStore.self) var wallet: WalletStore
    @Environment(\.navigate) var navigate: NavigateAction

    @State var selected: Set<String> = .init()
    @State private var sortOrder = [
        KeyPathComparator(\LocalOutput.txout.value, order: .reverse)
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Table(of: LocalOutput.self, selection: $selected, sortOrder: $sortOrder) {
                    TableColumn("OutPoint") { utxo in
                        Text(verbatim: "\(utxo.id)")
                            .truncationMode(.middle)
                    }
                    TableColumn("Value", value: \.txout.value.formatted)
                    TableColumn("Date") { utxo in
                        switch utxo.chainPosition {
                        case .confirmed(let time, _):
                            Text("\(time.confirmationTime.toDate().commonFormat())")
                        case .unconfirmed:
                            Text("Unconfirmed")
                        }
                    }
                } rows: {
                    ForEach(wallet.utxos) { utxo in
                        TableRow(utxo)
                            .contextMenu {
                                Button("Copy OutPoint") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(utxo.id, forType: .string)
                                }
                            }
                    }
                }
                .onChange(of: sortOrder, initial: true) { _, sortOrder in
                    wallet.utxos.sort(using: sortOrder)
                }
            }
            .safeAreaPadding(.bottom, 80)
            VStack {
                HStack {
                    Spacer()
                    GlassButton.primary("Send") {
                        navigate(.goto(.wallet(.send(selected: selected))))
                    }
                }
                .padding(.all)
                .glassEffect()
            }
            .padding(.all)
        }
        .toolbar {
            WalletStatusToolbar()
        }
    }
}

// #Preview {
//    UtxosView(selected: .constant(Set<String>()), walletVm: .init(global: .init()))
// }
