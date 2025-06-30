//
//  DevelopmentSettings.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/17.
//

import SwiftUI

struct DevelopmentSettings: View {
    @Environment(AppSettings.self) private var settings: AppSettings
    @Environment(\.modelContext) private var ctx

    var body: some View {
        Form {
            Section {
                Toggle("App First", isOn: settings.storage.$isFirst)
                LabeledContent("ServerUrl Model") {
                    Button("Erase") {
                        try! ctx.delete(model: ServerUrl.self)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}
