//
//  Settings.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/2.
//

import DecentralizedFFI
import Foundation
import LocalAuthentication
import SwiftData
import SwiftUI
import UserNotifications

@Model
final class ServerUrl {
    @Attribute(.unique)
    var url: String
    var type: String
    var network: String

    init(url: String, type: ServerType, network: Network) {
        self.url = url
        self.type = type.rawValue
        self.network = network.rawValue
    }
}

enum ServerType: String, CaseIterable, Identifiable, Codable, Equatable {
    case Esplora, Electrum, EsploraWss

    var id: String {
        rawValue
    }
}

struct StorageSettins {
    static let shared = StorageSettins()

    @AppStorage("isAppFirst")
    var isAppFirst: Bool = true

    @AppStorage("enableTouchID")
    var enableTouchID: Bool = false

    @AppStorage("touchID.app")
    var touchIDApp: Bool = false

    @AppStorage("touchID.sign")
    var touchIDSign: Bool = false

    @AppStorage("notification.newTx")
    var enableNotificationNewTx: Bool = false

    @AppStorage("notification.confirmedTx")
    var enableNotificationConfirmedTx: Bool = false

    @AppStorage("notification.removedTx")
    var enableNotificationRemovedTx: Bool = false

    @AppStorage("network")
    var network: Network = .bitcoin

    @AppStorage("severType")
    var serverType: ServerType = .Esplora

    @AppStorage("serverUrl")
    var serverUrl: String = "https://mempool.space/api"

    @AppStorage("wssUrl")
    var wssUrl: String = "wss://mempool.space/api/v1/ws"

    @AppStorage("isOnBoarding")
    var isOnBoarding: Bool = true

    @AppStorage("esploraUrl")
    var esploraUrl: String = "https://mempool.space/api"

    @AppStorage("enableCpfp")
    var enableCpfp: Bool = false
    
    @AppStorage("enableMempoolMonitor")
    var enableMempoolMonitor: Bool = false

    @AppStorage("runeUrl")
    var runeUrl: String = "https://www.okx.com/api/v5/wallet/utxo/utxo-detail?chainIndex=0&txHash={0}&voutIndex={1}"

    @AppStorage("runeAuth")
    var runeAuth: String = """
    {
        "Ok-Access-Key":"dead4a8a-598f-4710-8512-ddb5f1045ce0",
        "OK-ACCESS-SIGN":"hmac({timestamp}{request_method}{request_path},82F81D877AD377FC814A0BCB2D473283)",
        "OK-ACCESS-TIMESTAMP":"{timestamp}",
        "OK-ACCESS-PASSPHRASE":"Nieaowei360!",
        "OK-ACCESS-PROJECT":"fc4304bb854b4634fee86f00a10b0b5c"
    }
    """

    @AppStorage("runefallbackUrl")
    var runefallbackUrl: String = ""

    @AppStorage("runefallbackAuth")
    var runefallbackAuth: String = ""

    @AppStorage("runefallbackIdPath")
    var runefallbackIdPath: String = ""

    @AppStorage("runeIdPath")
    var runeIdPath: String = "$.data[0].btcAssets[0].nftId"

    @AppStorage("runeNamePath")
    var runeNamePath: String = "$.data[0].btcAssets[0].symbol"

    @AppStorage("runeDivPath")
    var runeDivPath: String = "$.data[0].btcAssets[0].decimal"

    @AppStorage("runeAmountPath")
    var runeAmountPath: String = "$.data[0].btcAssets[0].tokenAmount"

    @AppStorage("sameAsRune")
    var sameAsRune: Bool = false

    @AppStorage("inscriptionUrl")
    var inscriptionUrl: String = ""

    @AppStorage("inscriptionAuth")
    var inscriptionAuth: String = ""

    @AppStorage("inscriptionIdPath")
    var inscriptionIdPath: String = ""

    @AppStorage("inscriptionNamePath")
    var inscriptionNamePath: String = ""

    @AppStorage("inscriptionNumberPath")
    var inscriptionNumberPath: String = ""

    // for brc20 etc.
    @AppStorage("inscriptionAmountPath")
    var inscriptionAmountPath: String = ""

    @AppStorage("inscriptionDivPath")
    var inscriptionDivPath: String = ""
}

@Observable
class AppSettings {
    @ObservationIgnored
    var storage: StorageSettins = .shared

//    @AppStorage("enableNotifiaction")
//    @ObservationIgnored
    var enableNotification: Bool = false

    var changed: Bool = false

    var network: Network {
        storage.network
    }

    var accentColor: Color {
        network.accentColor
    }

    var isAppFirst: Bool = StorageSettins.shared.isAppFirst {
        didSet {
            storage.isAppFirst = isAppFirst
        }
    }

    var enableTouchID: Bool = StorageSettins.shared.enableTouchID {
        didSet {
            storage.enableTouchID = enableTouchID
        }
    }

    var touchIDApp: Bool = StorageSettins.shared.touchIDApp {
        didSet {
            storage.touchIDApp = touchIDApp
        }
    }

    var touchIDSign: Bool = StorageSettins.shared.touchIDSign {
        didSet {
            storage.touchIDSign = touchIDSign
        }
    }

    var enableNotificationNewTx: Bool = StorageSettins.shared.enableNotificationNewTx {
        didSet {
            storage.enableNotificationNewTx = enableNotificationNewTx
        }
    }

    var enableNotificationConfirmedTx: Bool = StorageSettins.shared.enableNotificationConfirmedTx {
        didSet {
            storage.enableNotificationConfirmedTx = enableNotificationConfirmedTx
        }
    }

    var enableNotificationRemovedTx: Bool = StorageSettins.shared.enableNotificationRemovedTx {
        didSet {
            storage.enableNotificationRemovedTx = enableNotificationRemovedTx
        }
    }

    var serverType: ServerType { storage.serverType }
    var serverUrl: String { storage.serverUrl }
    var wssUrl: String { storage.wssUrl }
    var isOnBoarding: Bool { storage.isOnBoarding }
    var esploraUrl: String { storage.esploraUrl }
    var enableCpfp: Bool { storage.enableCpfp }
    
    var enableMempoolMonitor: Bool { storage.enableMempoolMonitor }
    var runeUrl: String { storage.runeUrl }
    var runeAuth: String { storage.runeAuth }
    var runefallbackUrl: String { storage.runefallbackUrl }
    var runefallbackAuth: String { storage.runefallbackAuth }
    var runefallbackIdPath: String { storage.runefallbackIdPath }
    var runeIdPath: String { storage.runeIdPath }
    var runeNamePath: String { storage.runeNamePath }
    var runeDivPath: String { storage.runeDivPath }
    var runeAmountPath: String { storage.runeAmountPath }
    var sameAsRune: Bool { storage.sameAsRune }
    var inscriptionUrl: String { storage.inscriptionUrl }
    var inscriptionAuth: String { storage.inscriptionAuth }
    var inscriptionIdPath: String { storage.inscriptionIdPath }
    var inscriptionNamePath: String { storage.inscriptionNamePath }
    var inscriptionNumberPath: String { storage.inscriptionNumberPath }
    var inscriptionAmountPath: String { storage.inscriptionAmountPath }
    var inscriptionDivPath: String { storage.inscriptionDivPath }

//    var asyncStream: AsyncStream<Bool>

    init() {
//        self.asyncStream = AsyncStream { cont in
//            UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
//                @AppStorage("enableNotifiaction")
//                var enableNotifiaction: Bool = false
//                let auth = (settings.authorizationStatus == .authorized)
//                self?.enableNotifiaction = auth
//            }
//        }
    }

//    @MainActor
//    func set(_ isAuthorized: Bool) {
//        self.enableNotifiaction = isAuthorized
//    }
//
//    func getEnableNotifiaction() {}
}

@MainActor let staticServerUrls: [ServerUrl] = {
    var serverUrls: [ServerUrl] = [
        ServerUrl(url: "https://mempool.space/api", type: .Esplora, network: .bitcoin),
        ServerUrl(url: "https://blockstream.info/api", type: .Esplora, network: .bitcoin),
        ServerUrl(url: "https://btc-1.xverse.app", type: .Esplora, network: .bitcoin),
        ServerUrl(url: "https://bitcoin.lu.ke/api", type: .Esplora, network: .bitcoin),

        ServerUrl(url: "https://mempool.space/testnet/api", type: .Esplora, network: .testnet),
        ServerUrl(url: "https://blockstream.info/testnet/api", type: .Esplora, network: .testnet),
        ServerUrl(url: "https://btc-testnet.xverse.app", type: .Esplora, network: .testnet),

        ServerUrl(url: "https://mempool.space/testnet4/api", type: .Esplora, network: .testnet4),

        ServerUrl(url: "https://mempool.space/signet/api", type: .Esplora, network: .signet),
        ServerUrl(url: "https://blockstream.info/signet/api", type: .Esplora, network: .signet),
        ServerUrl(url: "https://btc-signet.xverse.app", type: .Esplora, network: .signet),

        // Electrum
//        ServerUrl(url: "ssl://electrum.blockstream.info:50002", type: .Electrum, network: .bitcoin),
        ServerUrl(url: "ssl://fulcrum.sethforprivacy.com:50002", type: .Electrum, network: .bitcoin),
        ServerUrl(url: "ssl://bitcoin.lu.ke:50002", type: .Electrum, network: .bitcoin),

//        ServerUrl(url: "ssl://electrum.emzy.de:50002", type: .Electrum, network: .bitcoin),
//        ServerUrl(url: "ssl://electrum.bitaroo.net:50002", type: .Electrum, network: .bitcoin),
//        ServerUrl(url: "ssl://electrum.diynodes.com:50002", type: .Electrum, network: .bitcoin),

        ServerUrl(url: "ssl://electrum.blockstream.info:60002", type: .Electrum, network: .testnet),

        ServerUrl(url: "ssl://mempool.space:40002", type: .Electrum, network: .testnet4),

        // Wss
        ServerUrl(url: "wss://mempool.space/api/v1/ws", type: .EsploraWss, network: .bitcoin),
        ServerUrl(url: "wss://bitcoin.lu.ke/api/v1/ws", type: .EsploraWss, network: .bitcoin),

        ServerUrl(url: "wss://mempool.space/testnet/api/v1/ws", type: .EsploraWss, network: .testnet),
        ServerUrl(url: "wss://mempool.emzy.de/testnet/api/v1/ws", type: .EsploraWss, network: .testnet),

        ServerUrl(url: "wss://mempool.space/testnet4/api/v1/ws", type: .EsploraWss, network: .testnet4),

        ServerUrl(url: "wss://mempool.space/signet/api/v1/ws", type: .EsploraWss, network: .signet)
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

    let wssUrls = [
        "blockstream.info",
        "emzy.de",
        "bitaroo.net",
        "diynodes.com"
    ]

    for url in wssUrls {
        serverUrls.append(ServerUrl(url: "wss://mempool.\(url)/api/v1/wss", type: .EsploraWss, network: .bitcoin))
    }

    return serverUrls

}()
