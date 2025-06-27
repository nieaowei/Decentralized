//
//  SignScreen.swift
//  Decentralized
//
//  Created by Nekilc on 2024/10/18.
//

import DecentralizedFFI
import SwiftUI

struct TxSignScreen: View {
    struct UnsignedPsbt: Hashable {
        let psbt: Psbt
        let walletType: WalletType
        var isSigned: Bool = false

        init(psbt: Psbt, walletType: WalletType = .pay, isSigned: Bool = false) {
            self.psbt = psbt
            self.walletType = walletType
            self.isSigned = isSigned
        }
    }

    @Environment(WalletStore.self) private var wallet: WalletStore
    @Environment(WssStore.self) private var wss: WssStore
    @Environment(\.showError) private var showError

    @Environment(\.dismiss) private var dismiss

    @State
    private var current: Int = 0

    @State
    var unsignedPsbts: [UnsignedPsbt]

    @State
    var deferBroadcastTxs: [DecentralizedFFI.Transaction]?

    @State
    private var showSuccess: Bool = false

    @State
    private var loading: Bool = false

    private var tx: DecentralizedFFI.Transaction {
        unsignedPsbts[current].psbt.extractTxUncheckedFeeRate()
    }

    private var isSigned: Bool {
        !unsignedPsbts.contains(where: { !$0.isSigned })
    }

    private var hex: String? {
        unsignedPsbts[current].isSigned ? unsignedPsbts[current].psbt.serializeHex() : nil
    }

    private var signText: String {
        if unsignedPsbts.count > 1 {
            (unsignedPsbts[current].isSigned ? "Signed" : "Sign") + " (\(current + 1)/\(unsignedPsbts.count))"
        } else {
            unsignedPsbts[current].isSigned ? "Signed" : "Sign"
        }
    }

//    init(psbts: [Psbt]) {
//        _unsignedPsbts = .init(wrappedValue: psbts.map { UnsignedPsbt(psbt: $0) })
//    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                if let hex {
                    GroupedBox("Signed Hex ", items: [
                        Text(verbatim: hex)
                            .textSelection(.enabled)
                    ])
                }
                TransactionDetailView(tx: wallet.createWalletTx(tx: tx))
            }
            .safeAreaPadding(.bottom, 80)
            VStack {
                HStack {
                    Spacer()
                    if current > 0 {
                        SecondaryButton("Last", action: { current -= 1 })
                    }
                    if current < unsignedPsbts.count - 1 && unsignedPsbts[current].isSigned {
                        SecondaryButton("Next", action: { current += 1 })
                    }
                    if !isSigned {
                        GlassButton.primary(LocalizedStringKey(signText), action: onSign)
                            .disabled(unsignedPsbts[current].isSigned)
                    } else {
                        GlassButton.primary("Broadcast", action: onBroadcast)
                    }
                }
                .padding(.all)
                .glassEffect()
            }
            .padding(.all)
        }
        .sheet(isPresented: $loading) {
            ProgressView()
                .padding(.all)
        }
        .sheet(isPresented: $showSuccess) {
            VStack {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle")
                        .resizable()
                        .frame(width: 64, height: 64)
                        .foregroundStyle(.green)
                    Text("Payment Sent")
                        .font(.title2)
                    Text("Your transaction has been successfully sent")
                        .font(.footnote)
                    GlassButton.primary("OK") {
                        dismiss()
                        showSuccess = false
                    }
                }
            }
            .padding(.all)
        }
        .navigationTitle("Send Transaction Detail")
    }

    func onSign() {
        Task {
            loading = true
            defer {
                self.loading = false
            }

            let ok = wallet.sign(unsignedPsbts[current].psbt, unsignedPsbts[current].walletType).inspectError { err in
                logger.error("Error signing transaction: \(err)")
                showError(err, "Signing transaction failed")
            }

            guard case .success(let ok) = ok, ok else {
                showError(nil, "Signing transaction failed")
                return
            }
            withAnimation {
                unsignedPsbts[current].isSigned = true
            }

            let tx = unsignedPsbts[current].psbt.extractTxUncheckedFeeRate()
            for (vout, output) in tx.output().enumerated() {
                wallet.insertTxout(op: OutPoint(txid: tx.computeTxid(), vout: UInt32(vout)), txout: TxOut(value: output.value, scriptPubkey: output.scriptPubkey, serializeHex: ""))
            }
        }
    }

    func onBroadcast() {
        Task {
            loading = true

            for unsignedPsbt in unsignedPsbts {
                let id = await wallet.broadcast(unsignedPsbt.psbt.extractTxUncheckedFeeRate())
                print(id)
            }
            if let addedBroadcast = deferBroadcastTxs {
                try await Task.sleep(nanoseconds: 3 * 1_000_000_000)
                for added in addedBroadcast {
                    let id = await wallet.broadcast(added)
                    print(id)
                }
            }
            self.loading = false
            showSuccess = true
        }
    }
}

// #Preview {
//    SignScreen()
// }
