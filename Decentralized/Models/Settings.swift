//
//  Settings.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/2.
//

import Foundation
import SwiftData
import SwiftUI
import UserNotifications

@Model
class ServerUrl {
    @Attribute(.unique)
    var url: String
    var type: ServerType
    var network: String
    
    init(url: String, type: ServerType, network: Networks) {
        self.url = url
        self.type = type
        self.network = network.rawValue
    }
}

enum ServerType: String, CaseIterable, Identifiable, Codable {
    case Esplora, Electrum

    var id: String {
        self.rawValue
    }
}

@Observable
class AppSettings {
    var enableNotifiaction: Bool = false

    @ObservationIgnored
    @AppStorage("isFirst")
    var isFirst: Bool = true

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

var staticServerUrls: [ServerUrl] = [
    ServerUrl(url: "https://mempool.space/api", type: .Esplora, network: .bitcoin),
    ServerUrl(url: "https://blockstream.info/api", type: .Esplora, network: .bitcoin),
    ServerUrl(url: "https://api.hiro.so", type: .Esplora,network: .bitcoin),
    ServerUrl(url: "https://btc-1.xverse.app", type: .Esplora, network: .bitcoin),
    
    ServerUrl(url: "https://mempool.space/testnet/api", type: .Esplora, network: .testnet),
    ServerUrl(url: "https://blockstream.info/testnet/api", type: .Esplora, network: .testnet),
    ServerUrl(url: "https://api.testnet.hiro.so", type: .Esplora,network: .testnet),
    ServerUrl(url: "https://btc-testnet.xverse.app", type: .Esplora, network: .testnet)
]
