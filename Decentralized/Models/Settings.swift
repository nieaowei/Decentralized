//
//  Settings.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/2.
//

import Foundation
import SwiftUI
import UserNotifications

enum ServerType: String, CaseIterable, Identifiable {
    case Esplora, Electrum

    var id: String {
        self.rawValue
    }
}


@Observable
class AppSettings{
    
    var enableNotifiaction: Bool = false
    
    @ObservationIgnored
    @AppStorage("network")
    var enableTouchID: Bool = false

    @ObservationIgnored
    @AppStorage("network")
    var network: Networks = .testnet
    
    @ObservationIgnored
    @AppStorage("severType")
    var serverType: ServerType = .Esplora

    @ObservationIgnored
    @AppStorage("serverUrl")
    var serverUrl: String = "https://mempool.space/api"
    
    @ObservationIgnored
    @AppStorage("isOnBoarding")
    var isOnBoarding: Bool = true

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
