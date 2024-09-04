//
//  MmemonicInputView.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/24.
//

import AppKit
import BitcoinDevKit
import SwiftUI

extension WordCount: @retroactive CaseIterable {
    public static var allCases: [WordCount] = [.words12, .words24]
    public var value: Int {
        switch self {
        case .words12:
            12
        case .words15:
            15
        case .words18:
            18
        case .words21:
            21
        case .words24:
            24
        }
    }
}

struct MmemonicInputView: View {
    @State var selection = WordCount.words12.value

    @State var words: [String] = .init(repeating: "", count: 24)

    @Binding var mnemonic: String

    var body: some View {
        Form {
            Section {
                VStack(spacing: 10) {
                    Picker("", selection: $selection) {
                        ForEach(WordCount.allCases, id: \.self) { item in
                            Text(verbatim: item.value.description).tag(item.value)
                        }
                    }
                    .pickerStyle(.segmented)

                    LazyVGrid(columns: [GridItem](repeating: GridItem(), count: 6)) {
                        ForEach(0 ..< selection, id: \.self) { index in
                            TextField("", text: $words[index])
                                .onChange(of: words) {
                                    let words_ = words[index].components(separatedBy: " ")
                                    if words_.count > 1 {
                                        for (i, word) in words_.enumerated() {
                                            words[i]  = word
                                        }
                                    }
                                    if words_.count == 12{
                                        selection = 12
                                    }
                                    if words_.count == 24{
                                        selection = 24
                                    }
                                }
                        }
                    }
                }
            }
        }
        .formStyle(.automatic)
        .onChange(of: words) {
            mnemonic = words.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        }
    }
}

#Preview {
    MmemonicInputView(mnemonic: .constant(""))
}
