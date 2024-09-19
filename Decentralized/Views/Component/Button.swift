//
//  Button.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/19.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal)
        }
        .primary()
    }
}


