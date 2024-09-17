//
//  BTCtApp.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/22.
//

import BitcoinDevKit
import SwiftData
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .providesAppNotificationSettings]) { ok, error in
            if let error = error {
                logger.error("Request Notification Authorization：\(error.localizedDescription)")
            }
            if ok {
                logger.info("Request Notification Success")
            } else {
                logger.error("Request Notification Falied")
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge, .banner])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // 处理通知响应
        completionHandler()
    }
}

@main
struct DecentralizedApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate

    @AppStorage("isOnBoarding") var isOnBoarding: Bool = true
    @Environment(\.openWindow) private var openWindow

    @State var settings: AppSettings
    @State var wallet: WalletStore
    @State var wss: WssStore
    @State private var errorWrapper: ErrorWrapper?
    @State var syncClient: SyncClient
    @State var loading: Bool = false

    let mainModelContainer: ModelContainer = try! ModelContainer(for: Contact.self, ServerUrl.self, configurations: ModelConfiguration())

    init() {
        logger.info("App Init")

        let settings = AppSettings()

        let syncClientInner = switch settings.serverType {
        case .Esplora:
            SyncClientInner.esplora(EsploraClient(url: settings.serverUrl))
        case .Electrum:
            SyncClientInner.electrum(try! ElectrumClient(url: settings.serverUrl))
        case .EsploraWss:
            fatalError()
        }

        let syncClient = SyncClient(inner: syncClientInner)

        let walletService = WalletService(network: settings.network, syncClient: syncClient)

        _settings = State(wrappedValue: settings)
        _wss = State(wrappedValue: .init(url: URL(string: settings.wssUrl)!))
        _syncClient = State(wrappedValue: syncClient)
        _wallet = State(wrappedValue: WalletStore(wallet: walletService))
    }

    var body: some Scene {
        WindowGroup {
            if isOnBoarding {
                OnBoradingView()
                    .toolbar(removing: .title)
                    .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                    .containerBackground(.thickMaterial, for: .window)
                    .windowMinimizeBehavior(.disabled)
                    .windowResizeBehavior(.disabled)
                    .sheet(item: $errorWrapper) { errorWrapper in
                        Text(errorWrapper.error.localizedDescription)
                    }
            } else {
                HomeView()
                    .onAppear{
                        wss.connect()
                    }
                    .onChange(of: settings.serverType) {
                        logger.info("serverType Change")
                        updateSyncClientInner()
                    }
                    .onChange(of: settings.serverUrl) {
                        logger.info("serverUrl Change")
                        updateSyncClientInner()
                    }
                    .onChange(of: settings.network) {
                        logger.info("network Change")
                        updateWallet()
                    }
                    .onChange(of: settings.changed) {
                        logger.info("settings Change")
                    }
                    .onChange(of: settings.wssUrl) {
                        logger.info("wssUrl Change")
                        updateWss()
                    }

                    .sheet(item: $errorWrapper) { errorWrapper in
                        VStack {
                            Text(errorWrapper.guidance)
                                .font(.title3)
                            Text(errorWrapper.error.localizedDescription)
                            Button {
                                self.errorWrapper = nil
                            } label: {
                                Text(verbatim: "OK")
                                    .padding(.horizontal)
                            }
                            .primary()
                        }
                        .padding(.all)
                    }
            }
        }
        .environment(wss)
        .environment(wallet)
        .environment(settings)
        .environment(syncClient)
        .environment(\.showError) { error, guidance in
            errorWrapper = ErrorWrapper(error: error, guidance: guidance)
        }
        .modelContainer(mainModelContainer)

        // Replace About Button Action
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button(action: {
                    openWindow(id: "about")
                }) {
                    Text("About Decentralized")
                }
            }
        }

        // Custom About
        Window("About", id: "about") {
            AboutView()
                .toolbar(removing: .title)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                .containerBackground(.thickMaterial, for: .window)
                .windowMinimizeBehavior(.disabled)
                .windowResizeBehavior(.disabled)
        }
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
        .commandsRemoved()

        Settings {
            SettingsView()
                .windowResizeBehavior(.enabled)
                .modelContainer(mainModelContainer)
        }
        .environment(settings)
        .environment(wallet)
        .windowIdealSize(.fitToContent)
        .windowResizability(.contentSize)
    }

    func updateSyncClientInner() {
        let syncClientInner = switch settings.serverType {
        case .Esplora:
            SyncClientInner.esplora(EsploraClient(url: settings.serverUrl))
        case .Electrum:
            SyncClientInner.electrum(try! ElectrumClient(url: settings.serverUrl))
        case .EsploraWss:
            fatalError()
        }
        syncClient.inner = syncClientInner
    }

    func updateWss() {
        wss.updateUrl(settings.wssUrl )
    }

    func updateWallet() {
        wallet = WalletStore(wallet: WalletService(network: settings.network, syncClient: syncClient))
    }
}
