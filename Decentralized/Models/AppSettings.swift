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
    var type: String
    var network: String

    init(url: String, type: ServerType, network: Networks) {
        self.url = url
        self.type = type.rawValue
        self.network = network.rawValue
    }
}

enum ServerType: String, CaseIterable, Identifiable, Codable, Equatable {
    case Esplora, Electrum

    var id: String {
        self.rawValue
    }

}

@Observable
class AppSettings {
    var enableNotifiaction: Bool = false

    var changed: Bool = false

    var accentColor: Color = .blue

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

var staticServerUrls: [ServerUrl] = {
    var serverUrls: [ServerUrl] = [
        ServerUrl(url: "https://mempool.space/api", type: .Esplora, network: .bitcoin),
        ServerUrl(url: "https://blockstream.info/api", type: .Esplora, network: .bitcoin),
        ServerUrl(url: "https://btc-1.xverse.app", type: .Esplora, network: .bitcoin),
        ServerUrl(url: "https://bitcoin.lu.ke/api", type: .Esplora, network: .bitcoin),

        ServerUrl(url: "https://mempool.space/testnet/api", type: .Esplora, network: .testnet),
        ServerUrl(url: "https://blockstream.info/testnet/api", type: .Esplora, network: .testnet),
        ServerUrl(url: "https://btc-testnet.xverse.app", type: .Esplora, network: .testnet),

        ServerUrl(url: "https://mempool.space/signet/api", type: .Esplora, network: .signet),
        ServerUrl(url: "https://blockstream.info/signet/api", type: .Esplora, network: .signet),
        ServerUrl(url: "https://btc-signet.xverse.app", type: .Esplora, network: .signet),

//        ServerUrl(url: "ssl://electrum.blockstream.info:50002", type: .Electrum, network: .bitcoin),
        ServerUrl(url: "ssl://fulcrum.sethforprivacy.com:50002", type: .Electrum, network: .bitcoin),
        ServerUrl(url: "ssl://bitcoin.lu.ke:50002", type: .Electrum, network: .bitcoin),

//        ServerUrl(url: "ssl://electrum.emzy.de:50002", type: .Electrum, network: .bitcoin),
//        ServerUrl(url: "ssl://electrum.bitaroo.net:50002", type: .Electrum, network: .bitcoin),
//        ServerUrl(url: "ssl://electrum.diynodes.com:50002", type: .Electrum, network: .bitcoin),

        ServerUrl(url: "ssl://electrum.blockstream.info:60002", type: .Electrum, network: .testnet)
    ]

    let mempoolUrls = [
        "blockstream.info",
        "emzy.de",
        "bitaroo.net",
        "diynodes.com"
    ]

    for url in mempoolUrls {
        serverUrls.append(ServerUrl(url: "https://mempool.\(url)/api", type: .Esplora, network: .bitcoin))
    }

    let electrumUrls = [
        "blockstream.info",
        "emzy.de",
        "bitaroo.net",
        "diynodes.com"
    ]
    for url in electrumUrls {
        serverUrls.append(ServerUrl(url: "ssl://electrum.\(url):50002", type: .Electrum, network: .bitcoin))
    }

    return serverUrls

}()
