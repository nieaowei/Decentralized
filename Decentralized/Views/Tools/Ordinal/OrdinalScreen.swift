//
//  OrdinalMintScreen.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/24.
//

import DecentralizedFFI
import QuickLook
import QuickLookUI
import SwiftUI

struct OrdinalMintPair: Hashable {
    var commitPsbt: Psbt
    var revealTx: DecentralizedFFI.Transaction
}

struct OrdinalScreen: View {
    @Environment(AppSettings.self) private var settings
    @Environment(WalletStore.self) private var wallet

    @State var selection: String = "Text"

    @State var mintPair: OrdinalMintPair? = nil

    var body: some View {
        ScrollView {
            Picker("", selection: $selection) {
                Text("Text").tag("Text")
                Text("File").tag("File")
                Text("BRC20").tag("BRC20")
            }
            .pickerStyle(.palette)
            switch selection {
                case "Text":
                    TextMintView(mintPair: $mintPair)
                case "File":
                    FileMintView(mintPair: $mintPair)
                case "BRC20":
                    BRC20MintView(mintPair: $mintPair)
                default:
                    FileMintView(mintPair: $mintPair)
            }
        }
        .padding(.all)
        .toolbar {
            WalletStatusToolbar()
        }
        .navigationDestination(item: $mintPair) { psbt in
            SignScreen(unsignedPsbts: [SignScreen.UnsignedPsbt(psbt: psbt.commitPsbt)], deferBroadcastTxs: [psbt.revealTx])
        }
    }
}



#Preview {
    OrdinalScreen()
}
