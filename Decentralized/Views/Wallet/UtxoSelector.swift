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

    var body: some View {
        VStack {
            Table(of: LocalOutput.self,selection: $selected) {
                TableColumn("OutPoint") { utxos in
                    Text(utxos.id)
                        .truncationMode(.middle)
                }
                TableColumn("Value", value: \.txout.value.formatted)
            } rows: {
                ForEach(utxos) { u in
                    TableRow(u)
                }
            }
            .truncationMode(.middle)
        }
        .onAppear {
            self.utxos.removeAll { lo in
                selected.contains(lo.id)
            }
        }
    }
}
