//
//  SettingsView.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/28.
//

import Combine
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings: AppSettings
    @Environment(\.modelContext) private var ctx

    var body: some View {
        TabView {
            Tab("Server", systemImage: "server.rack") {
                ServerSettings()
            }
            Tab("Notifaction", systemImage: "bell.badge") {
                NotificationSettings()
            }
            Tab("Wallet", systemImage: "dollarsign.circle") {
                WalletSettings()
            }
//            Tab("Safe", systemImage: "lock.shield") {
//                ServerSettings()
//            }
            Tab("Development", systemImage: "hammer") {
                DevelopmentSettings()
            }
        }
        .scenePadding()
        .onAppear {
            if settings.isFirst {
                settings.isFirst = false
                for i in staticServerUrls {
                    ctx.insert(i)
                }
                try! ctx.save()
            }
        }
    }
}





// #Preview {
//    SettingsView()
// }
