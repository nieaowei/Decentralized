//
//  BoardcastView.swift
//  Decentralized
//
//  Created by Nekilc on 2024/7/19.
//

import BitcoinDevKit
import SwiftUI



struct BroadcastView: View {
    @State var sigedHex: String = ""
    @State var showTxid: String? = nil
    @State var tx: BitcoinDevKit.Transaction? = nil

    @State var errorMsg: String? = nil
    @State var showError: Bool = false
    var body: some View {
        
            VStack {
                
                TextEditor(text: $sigedHex)
                    .textEditorStyle(.automatic)
                    .contentMargins(10, for: .scrollContent)
                HStack{
                    Spacer()
                    Button {
                        onExtract()
                    } label: {
                        Text("Extract Hex")
                    }
                    .primary()
                    .navigationDestination(item: $tx) { tx in
                        SendDetailView(walletVm: .init(global: .live), tx: tx, txBuilder: .constant(.init()))
                    }
                }
                .padding(.all)
            }
        
        .alert("Invalid transaction hex string", isPresented: $showError, actions: {
            Button {
                showError.toggle()
            } label: {
                Text(verbatim: "close")
            }
            
        })
        .sheet(item: $showTxid) { _ in
            
        }
    }

    func onExtract() {
        do {
            tx = try BitcoinDevKit.Transaction(transactionBytes: sigedHex.hexStringToByteArray())
        } catch {
            logger.error("\(error.localizedDescription)")
            errorMsg = "Invalid Transaction hex"
            showError.toggle()
        }
    }
}

#Preview {
    BroadcastView()
}
