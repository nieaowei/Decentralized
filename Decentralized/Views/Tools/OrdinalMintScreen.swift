//
//  OrdinalMintScreen.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/24.
//

import SwiftUI

struct OrdinalMintScreen: View {
    @State var selection: String = ""

    var body: some View {
        ScrollView {
            Picker("", selection: $selection) {
                Text("Mint").tag("Mint")
                Text("Deploy").tag("Deploy")
            }
            .pickerStyle(.palette)
//            Form {
                Picker("", selection: .constant("")) {
                    Text("Mint").tag("Mint")
                    Text("Deploy").tag("Deploy")
                }
                .pickerStyle(.radioGroup)
                TextEditor(text: .constant("dadad"))
                    .textEditorStyle(.automatic)
                    .contentMargins(10, for: .scrollContent)
                TextField("Reciver", text: .constant("bc1p..."))
                
//            }
//            .formStyle(.grouped)
        }
        .padding(.all)
    }
}

#Preview {
    OrdinalMintScreen()
}
