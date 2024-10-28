//
//  Button.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/19.
//

import SwiftUI

struct PrimaryButton<Label: View>: View {
    var title: String? = nil
    let action: () -> Void
    var label: Label? = nil

    init(action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(action: action) {
            if let label {
                label
            }
            if let title {
                Text(title)
                    .padding(.horizontal)
            }
        }
        .primary()
    }
}

extension PrimaryButton where Label == Text {
    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
}



struct SecondaryButton<Label: View>: View {
    var title: String? = nil
    let action: () -> Void
    var label: Label? = nil

    init(action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(action: action) {
            if let label {
                label
            }
            if let title {
                Text(title)
                    .padding(.horizontal)
            }
        }
        .secondary()
    }
}

extension SecondaryButton where Label == Text {
    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
}
