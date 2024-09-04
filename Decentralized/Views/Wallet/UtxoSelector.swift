//
//  UtxoSelector.swift
//  BTCt
//
//  Created by Nekilc on 2024/7/10.
//
import BitcoinDevKit
import SwiftUI

struct UtxoSelector: View {
    @Binding var selected: Set<String>

    @State var utxos: [LocalOutput]

    var body: some View {
        VStack {
            Table(utxos, selection: $selected) {
                TableColumn("OutPoint") { utxos in
                    Text(utxos.id)
                        .truncationMode(.middle)
                }
                TableColumn("Value", value: \.diplayBTCValue)
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
