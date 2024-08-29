//
//  Utxos.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/23.
//

import BitcoinDevKit
import SwiftUI

struct UtxosView: View {
    @Binding var selected: Set<String>
    @Bindable var walletVm: WalletViewModel

    var body: some View {
        VStack {
            Table(walletVm.utxos, selection: $selected) {
                TableColumn("OutPoint") { utxo in
                    Text(verbatim: "\(utxo.id)")
                        .truncationMode(.middle)
                }
                TableColumn("Value", value: \.diplayBTCValue)
            }
            HStack {
                Spacer()
                Button(action: {
                    print(selected)
                    NotificationManager().sendNotification(title: "T1est", subtitle: "btcc", body: "1123234")
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

#Preview {
    UtxosView(selected: .constant(Set<String>()), walletVm: .init(global: .init()))
}
