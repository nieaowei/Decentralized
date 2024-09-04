//
//  BTCtApp.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/22.
//

import BitcoinDevKit
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

    @State var settings: Setting = .init()
    @State var wallet: WalletStore?
    @State var global: GlobalStore = .init()
    @State private var errorWrapper: ErrorWrapper?

    init() {
        let walletService = WalletService(network: settings.network.toBdkNetwork(), syncClient: .esplora(EsploraClient(url: settings.serverUrl)))
//        print("\(settings.serverUrl)")
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
                        Text(errorWrapper.error.localizedDescription)
                    }
            }
        }
        .environment(global)
        .environment(wallet)
        .environment(settings)
        .environment(\.showError) { error, guidance in
            errorWrapper = ErrorWrapper(error: error, guidance: guidance)
        }

        .modelContainer(for: Contact.self)
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
        }
        .environment(settings)
        .environment(wallet)
    }
}
