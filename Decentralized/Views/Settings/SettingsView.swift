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
            Tab("Notification", systemImage: "bell.badge") {
                NotificationSettings()
            }
            Tab("Wallet", systemImage: "dollarsign.circle") {
                WalletSettings()
            }
            Tab("MempoolMonitor", systemImage: "leaf") {
                MempoolMonitorSettings()
            }
            Tab("Safe", systemImage: "lock.shield") {
                SafeSettingsView()
            }
            Tab("Development", systemImage: "hammer") {
                DevelopmentSettings()
            }
        }
        .scenePadding()
        .onAppear {
            if settings.isFirst {
                settings.storage.isFirst = false
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
