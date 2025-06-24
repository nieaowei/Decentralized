//
//  UtxoSelector.swift
//  BTCt
//
//  Created by Nekilc on 2024/7/10.
//
import DecentralizedFFI
import SwiftUI

struct UtxoSelector: View {
    @Binding var selected: Set<String>

    @State var utxos: [LocalOutput]

    @State private var tableUtxos: [LocalOutput] = []

    @State private var sortOrder: [KeyPathComparator] = [KeyPathComparator(\LocalOutput.txout.value, order: .reverse)]

    @State private var search: String = ""
    var body: some View {
        NavigationView {
            Table(of: LocalOutput.self, selection: $selected, sortOrder: $sortOrder) {
                TableColumn("OutPoint") { utxos in
                    Text(utxos.id)
                        .truncationMode(.middle)
                }
                TableColumn("Value", value: \.txout.value.formatted)
            } rows: {
                ForEach(tableUtxos) { u in
                    TableRow(u)
                }
            }
            .truncationMode(.middle)
        }
        .onChange(of: sortOrder, initial: true) { _, sortOrder in
            tableUtxos.sort(using: sortOrder)
        }
        .onAppear {
            self.utxos.removeAll { lo in
                selected.contains(lo.id)
            }
            self.tableUtxos = self.utxos
        }
        .searchable(text: $search, prompt: "TxID Or OutpointID")
        .onChange(of: search) { _, newValue in

            self.tableUtxos = newValue.isEmpty ? self.utxos : self.utxos.filter { lo in
                lo.id.contains(newValue)
            }
        }
    }
}
