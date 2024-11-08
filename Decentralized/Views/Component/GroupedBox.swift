//
//  GroupedBox.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/1.
//

import SwiftUI

//todo optimize

struct GroupedBox: View {
    let items: [AnyView]
    var title: String? = nil

    init(_ title: String, items: [any View]) {
        self.title = title
        self.items = items.map { view in
            AnyView(view)
        }
    }

    init(_ items: [any View]) {
        self.items = items.map { view in
            AnyView(view)
        }
    }

    var body: some View {
        GroupBox {
            ForEach(items.indices, id: \.self) { i in

                if i == 0 {
                    items[i]
                        .padding(.top, 3)
                } else if i == items.endIndex-1 {
                    items[i]
                        .padding(.bottom, 3)
                } else {
                    items[i]
                }
                if i != items.endIndex-1 {
                    Divider()
                        .padding(.horizontal, 5)
                }
            }

        } label: {
            if let title {
                Text(NSLocalizedString(title, comment: ""))
                    .font(.headline)
                    .padding(.vertical, 10)
            }
        }
        .padding(.horizontal, 20)
    }
}

struct GroupedLabeledContent<Content: View>: View {
    let content: Content
    let title: String

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .top) {
            Text(NSLocalizedString(title, comment: ""))
            Spacer()
            content
                .textSelection(.enabled)
                .foregroundStyle(.gray)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 1)
    }
}
