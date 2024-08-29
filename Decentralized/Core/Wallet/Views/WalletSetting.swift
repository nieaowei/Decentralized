//
//  WalletSetting.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/23.
//

import SwiftUI

enum WalletType {
    case unisat
    case xverse
    case leather
    case peek
}

struct WalletSetting: View {
    @State var selection = "Tag"
    @State var mnemonic = ""
    var body: some View {
        HSplitView{
            VStack(content: {
                Form(content: {
                    Section {
                        TextField(
                            "Mnemonic",
                            text: $mnemonic
                        )
                        Picker(
                            "Wallet Type",
                            selection: $selection
                        ) {
                            Text(verbatim: "Unisat").tag("Tag")
                            Text(verbatim: "Xverse").tag("Tag2")
                            Text(verbatim: "Leather").tag("Tag3")
                            Text(verbatim: "Peek").tag("Tag4")
                        }
                        .pickerStyle(.segmented)
                    }
                })
                Spacer()
            })
            
            VStack(content: {
                Form(content: {
                    Section {
                        TextField(
                            "Mnemonic",
                            text: $mnemonic
                        )
                        Picker(
                            "Wallet Type",
                            selection: $selection
                        ) {
                            Text(verbatim: "Unisat").tag("Tag")
                            Text(verbatim: "Xverse").tag("Tag2")
                            Text(verbatim: "Leather").tag("Tag3")
                            Text(verbatim: "Peek").tag("Tag4")
                        }
                        .pickerStyle(.segmented)
                    }
                })
                Spacer()
            })
        }
    }
}

#Preview {
    WalletSetting(selection: "")
}
