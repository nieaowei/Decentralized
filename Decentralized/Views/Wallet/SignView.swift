//
//  SignView.swift
//  Decentralized
//
//  Created by Nekilc on 2024/8/30.
//

import DecentralizedFFI
import SwiftUI

struct SignView: View {
    @Environment(\.showError) var showError

    @State var psbtHex: String = ""
    @State var psbt: Psbt? = nil

    var body: some View {
        VStack {
            TextEditor(text: $psbtHex)
                .textEditorStyle(.automatic)
                .multilineTextAlignment(.leading)
                .scrollIndicators(.hidden)
            HStack {
                Spacer()
                PrimaryButton("Sign") {
                    onExtract()
                }
            }
            .padding(.all)
        }
        .navigationDestination(item: $psbt) { psbt in
            SignScreen(unsignedPsbts: [SignScreen.UnsignedPsbt(psbt: psbt)])
        }
    }

    func onExtract() {
        guard case .success(let psbt) = Psbt.fromHex(psbtHex).inspectError({ error in
            showError(error, "Invalid PSBT Hex")
        }) else {
            return
        }
        withAnimation {
            self.psbt = psbt
        }
    }
}
