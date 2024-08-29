//
//  SettingViewModel.swift
//  Decentralized
//
//  Created by Nekilc on 2024/7/18.
//

import Foundation
import Observation
import SwiftUI
import UserNotifications

enum ServerType: String, CaseIterable, Identifiable {
    case Esplora, Electrum

    var id: String {
        self.rawValue
    }
}

@Observable
class SettingsViewModel {
    var enableNotifiaction: Bool = false

    @ObservationIgnored
    @AppStorage("severType")
    var serverType: ServerType = .Esplora

    @ObservationIgnored
    @AppStorage("serverUrl")
    var serverUrl: String = "https://mempool.space"

    init() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            self.enableNotifiaction = (settings.authorizationStatus == .authorized)
        }
    }

    func getEnableNotifiaction() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.enableNotifiaction = (settings.authorizationStatus == .authorized)
    }
}
