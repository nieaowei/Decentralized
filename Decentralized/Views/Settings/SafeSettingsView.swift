//
//  SafeSettingsView.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/18.
//


import SwiftUI

struct SafeSettingsView:View{
    @Environment(AppSettings.self) private var settings: AppSettings

    var body: some View{
        Form{
            Toggle("Touch ID", isOn: settings.$enableTouchID)
        }
        .formStyle(.grouped)
    }
}
