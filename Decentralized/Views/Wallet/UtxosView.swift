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
        VStack {
            Table(of: LocalOutput.self, selection: $selected, sortOrder: $sortOrder) {
                TableColumn("OutPoint") { utxo in
                    Text(verbatim: "\(utxo.id)")
                        .truncationMode(.middle)
                }
                TableColumn("Value", value: \.txout.value.formatted)
                TableColumn("Date") { utxo in
                    switch utxo.confirmationTime {
                    case .confirmed(_, let time):
                        Text("\(time.toDate().commonFormat())")
                    case .unconfirmed(_):
                        Text("Unconfirmed")
                    }
                }
            } rows: {
                ForEach(wallet.utxos){ utxo in
                    TableRow(utxo)
                        .contextMenu {
                            Button("Copy OutPoint"){
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(utxo.id, forType: .string)
                            }
                        }
                }
                
            }
            .onChange(of: sortOrder, initial: true) { _, sortOrder in
                wallet.utxos.sort(using: sortOrder)
            }
            HStack {
                Spacer()
                Button(action: {
                    navigate(.goto(.wallet(.send(selected: selected))))
                }, label: {
                    Text("Send")
                        .padding(.horizontal)
                })
                .controlSize(.large)
                .buttonStyle(BorderedProminentButtonStyle())
            }
            .padding(.all)
        }
        .toolbar{
            WalletStatusToolbar()
        }
    }
}

// #Preview {
//    UtxosView(selected: .constant(Set<String>()), walletVm: .init(global: .init()))
// }
