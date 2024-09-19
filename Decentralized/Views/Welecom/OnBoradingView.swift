//
//  OnBoradingView.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/24.
//

import SwiftUI

struct OnBoradingView: View {
    @Environment(AppSettings.self) var settings
    @Environment(\.openSettings) var openSettings

    @State var mnemonic: String = ""
    @State var mode: WalletMode = .xverse
    @State var loading: Bool = false

    @AppStorage("isOnBoarding")
    var isOnboarding: Bool?

    var body: some View {
        VStack {
            if !loading {
                VStack {
                    HStack {
                        Image("Icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .shadow(radius: 10)

                        Text(verbatim: "Decentralized")
                            .font(.largeTitle)
                    }
                    VStack(spacing: 10) {
                        Picker("", selection: $mode) {
                            ForEach(WalletMode.allCases, id: \.self) { item in
                                Text(verbatim: item.rawValue.capitalized).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                        MmemonicInputView(mnemonic: $mnemonic)
                    }
                    Spacer()
                    Button {
                        do {
                            loading = true
                            let _ = try WalletService.create(words: mnemonic, mode: mode, network: settings.network)
                            isOnboarding = false

                        } catch {}
                    } label: {
                        Text("Enter")
                            .padding(.horizontal)
                    }
                    .primary()
                }
                .padding(.all)
            } else {
                ProgressView {
                    Text("Creating")
                }
            }
        }
    }
}

#Preview {
    OnBoradingView()
}
