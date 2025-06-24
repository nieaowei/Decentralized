//
//  Button.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/19.
//

import SwiftUI

struct GlassButton: View {
    var titleKey: LocalizedStringKey
    var action: () -> Void
    var color: Color

    var body: some View {
        Button(action: action) {
            Text(titleKey)
                .foregroundStyle(color)
                .padding(.horizontal)
        }
        .buttonStyle(.glass)
    }

    // static 构造器（调用中转 view）
    static func primary(_ titleKey: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        GlassButtonPrimaryFactory(titleKey: titleKey, action: action)
            .controlSize(.large)
    }

    static func close(_ titleKey: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        GlassButton(titleKey: titleKey, action: action, color: .red)
    }

    static func cancel(_ titleKey: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        GlassButton(titleKey: titleKey, action: action, color: .secondary)
    }

    private struct GlassButtonPrimaryFactory: View {
        @Environment(AppSettings.self) var settings
        let titleKey: LocalizedStringKey
        let action: () -> Void

        var body: some View {
            GlassButton(titleKey: titleKey, action: action, color: settings.accentColor)
        }
    }
}

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
