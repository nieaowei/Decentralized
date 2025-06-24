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
        ZStack(alignment: .bottom) {
            TextEditor(text: $psbtHex)
                .textEditorStyle(.automatic)
                .multilineTextAlignment(.leading)
                .scrollIndicators(.hidden)
                .safeAreaPadding(.bottom, 80)
            VStack {
                HStack {
                    Spacer()
                    GlassButton.primary("Sign") {
                        onExtract()
                    }
                
                }
                .padding(.all)
                .glassEffect()
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
