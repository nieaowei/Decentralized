//
//  SignView.swift
//  Decentralized
//
//  Created by Nekilc on 2024/8/30.
//

import BitcoinDevKit
import SwiftUI

struct SignView: View {
    @State var psbtHex: String = ""
    @State var showTxid: String? = nil
    @State var tx: BitcoinDevKit.Transaction? = nil
    
    @State var errorMsg: String? = nil
    @State var showError: Bool = false
    var body: some View {
        
            VStack {
                TextEditor(text: $psbtHex)
                    .textEditorStyle(.automatic)
                    .contentMargins(10, for: .scrollContent)
                HStack {
                    Spacer()
                    Button {
                        onExtract()
                    } label: {
                        Text("Extract Hex")
                    }
                    .primary()
//                    .navigationDestination(item: $tx) { tx in
//                        SendDetailView( tx: tx, txBuilder: .constant(.init()))
//                    }
                }
                .padding(.all)
            }
        
        .alert("Invalid Transaction hex", isPresented: $showError, actions: {
            Button {
                showError.toggle()
            } label: {
                Text(verbatim: "Close")
            }
            
        })
        .sheet(item: $showTxid) { _ in
        }
    }
    
    func onExtract() {
        do {
            print(psbtHex)
            let psbt = try Psbt.fromHex(psbtHex: psbtHex)
            tx = try psbt.extractTx()
        } catch {
            logger.error("\(error.localizedDescription)")
            errorMsg = "Invalid Transaction hex"
            showError.toggle()
        }
    }
}
