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
    @State var global: WssStore
    @State private var errorWrapper: ErrorWrapper?
    @State var syncClient: SyncClient
    @State var loading: Bool = false

    let mainModelContainer: ModelContainer

    init() {

        mainModelContainer = try! ModelContainer(for: Contact.self, ServerUrl.self, configurations: ModelConfiguration())

        let settings = AppSettings()

        let syncClientInner = switch settings.serverType {
        case .Esplora:
            SyncClientInner.esplora(EsploraClient(url: settings.serverUrl))
        case .Electrum:
            SyncClientInner.electrum(try! ElectrumClient(url: settings.serverUrl))
        }
        let syncClient = SyncClient(inner: syncClientInner)

        let walletService = WalletService(network: settings.network.toBdkNetwork(), syncClient: syncClient)

        _settings = State(wrappedValue: settings)
        _global = State(wrappedValue: .init())
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
        .environment(global)
        .environment(wallet)
        .environment(settings)
        .environment(syncClient)
        .environment(\.showError) { error, guidance in
            errorWrapper = ErrorWrapper(error: error, guidance: guidance)
        }
//        .environment(\.loading, false)
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
                .containerBackground(.thickMaterial, for: .window)
                .scaledToFit()
                .modelContainer(mainModelContainer)
                .onChange(of: settings.serverType) {
                    updateSyncClientInner()
                }
                .onChange(of: settings.serverUrl) {
                    updateSyncClientInner()
                }
        }
        .environment(settings)
        .environment(wallet)
    }

    func updateSyncClientInner() {
        let syncClientInner = switch settings.serverType {
        case .Esplora:
            SyncClientInner.esplora(EsploraClient(url: settings.serverUrl))
        case .Electrum:
            SyncClientInner.electrum(try! ElectrumClient(url: settings.serverUrl))
        }
        syncClient.inner = syncClientInner
    }
}
