//
//  OnBoradingView.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/24.
//

import SwiftUI

struct OnBoradingView: View {
    @State var vm = OnBoradingViewModel()

    @AppStorage("isOnBoarding") var isOnBoarding: Bool?

    var body: some View {
        VStack {
            if !vm.isLoading {
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
                        Picker("", selection: $vm.mode) {
                            ForEach(WalletMode.allCases, id: \.self) { item in
                                Text(verbatim: item.rawValue.capitalized).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                        MmemonicInputView(mnemonic: $vm.mnemonic)
                    }
                    Spacer()
                    Button(action: vm.createWallet) {
                        Text("Enter")
                            .padding(.horizontal)
                    }
                    .primary()
                }
                .padding(.all)
            } else {
                ProgressView {
                    Text(verbatim: "Creating")
                }
            }
        }
        .frame(maxHeight: .infinity)
        .alert(isPresented: $vm.showError, content: {
            Alert(
                title: Text(vm.onboardingViewError?.description ?? "Unknown"),
                message: nil,
                dismissButton: .default(Text("OK")) {
                    vm.onboardingViewError = nil
                }
            )
        })
    }
}

#Preview {
    OnBoradingView()
}
