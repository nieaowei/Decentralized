//
//  SafeSettingsView.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/18.
//

import SwiftUI

struct SafeSettingsView: View {
    @Environment(AppSettings.self) private var settings: AppSettings
    @Environment(\.isFocused) private var isFocused
    @Environment(\.resetFocus) private var resetFocus
    let currentWindow = NSApp.keyWindow

    private var enableTouchID: Binding<Bool> {
        Binding(
            get: { settings.enableTouchID },
            set: { newVal in
                Task {
                    if case .success = await auth() {
                        settings.enableTouchID = newVal
                    }
                }
            }
        )
    }

    private var touchIDApp: Binding<Bool> {
        Binding(
            get: { settings.touchIDApp },
            set: { newVal in
                Task {
                    if case .success = await auth() {
                        settings.touchIDApp = newVal
                    }
                }
            }
        )
    }

    private var touchIDSign: Binding<Bool> {
        Binding(
            get: { settings.touchIDSign },
            set: { newVal in
                Task {
                    if case .success = await auth() {
                        settings.touchIDSign = newVal
                    }
                }
            }
        )
    }

    var body: some View {
        VStack {
            Form {
                Toggle("Touch ID", isOn: enableTouchID)

                if settings.enableTouchID {
                    Section("Touch ID") {
                        Toggle("App", isOn: touchIDApp)
                        Toggle("Sign", isOn: touchIDSign)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .onAppear {
            print(isFocused)
//            resetFocus(in: Namespace.init())
//            print(isFocused)
        }
    }
}
