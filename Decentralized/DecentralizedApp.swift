//
//  BTCtApp.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/22.
//

import DecentralizedFFI
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
        completionHandler()
    }
}

@main
struct DecentralizedApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate

    @AppStorage("isOnBoarding") var isOnBoarding: Bool = true
    @Environment(\.openWindow) private var openWindow

    @State var settings: AppSettings
    let mainModelContainer: ModelContainer = try! ModelContainer(for: Contact.self, ServerUrl.self, CPFPChain.self, MempoolOrdinal.self, RuneInfo.self, InscriptionCollection.self, configurations: ModelConfiguration())

    let esploraClient: EsploraClientWrap
    @State var wss: WssStore

    @State private var errorWrapper: ErrorWrapper?

//    @State private var accentColor: Color
    @AppStorage("network")
    var network: Networks = .bitcoin

    init() {
        let settings = AppSettings()
        logger.info("App Init \(settings.network.rawValue)")
        logger.info("App Init \(settings.serverUrl)")

        self.esploraClient = EsploraClientWrap(inner: EsploraClient(url: settings.esploraUrl))
        self.settings = settings
        _wss = State(wrappedValue: .init(url: URL(string: settings.wssUrl)!))
        self.mainModelContainer.mainContext.autosaveEnabled = true
//        self.accentColor = settings.accentColor
    }

    var body: some Scene {
        WindowGroup {
            if self.isOnBoarding {
                OnBoradingView()
                    .tint(self.network.accentColor)
                    .toolbar(removing: .title)
                    .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                    .containerBackground(.thickMaterial, for: .window)
                    .windowMinimizeBehavior(.disabled)
                    .windowResizeBehavior(.disabled)
                    .sheet(item: self.$errorWrapper) { errorWrapper in
                        Text(errorWrapper.guidance)
                            .font(.title3)
                        if let error = errorWrapper.error {
                            Text(error.localizedDescription)
                        }
                    }

            } else {
                HomeView(self.settings)
                    .tint(self.network.accentColor)
                    .sheet(item: self.$errorWrapper) { errorWrapper in
                        VStack {
                            Text(errorWrapper.guidance)
                                .font(.title3)
                            if let error = errorWrapper.error {
                                Text(error.localizedDescription)
                            }
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
        .environment(self.settings)
        .environment(self.esploraClient)
        .environment(self.wss)
        .environment(\.showError) { error, guidance in
            self.errorWrapper = ErrorWrapper(error: error, guidance: guidance)
        }
        .modelContainer(self.mainModelContainer)

        // Replace About Button Action
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button(action: {
                    self.openWindow(id: "about")
                }) {
                    Text("About Decentralized")
                }
            }
        }

        Window("Welcome", id: "welcom") {
            OnBoradingView()
                .tint(self.network.accentColor)
                .toolbar(removing: .title)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                .containerBackground(.thickMaterial, for: .window)
                .windowMinimizeBehavior(.disabled)
                .windowResizeBehavior(.disabled)
                .sheet(item: self.$errorWrapper) { errorWrapper in
                    if let error = errorWrapper.error {
                        Text(error.localizedDescription)
                    }
                }
        }
        .environment(self.settings)

        // Custom About
        Window("About", id: "about") {
            AboutView()
                .toolbar(removing: .title)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                .containerBackground(.thickMaterial, for: .window)
                .windowMinimizeBehavior(.disabled)
                .windowResizeBehavior(.disabled)
                .tint(self.network.accentColor)
        }
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
        .commandsRemoved()

        Settings {
            SettingsView()
                .windowResizeBehavior(.enabled)
                .modelContainer(self.mainModelContainer)
                .tint(self.network.accentColor)
        }
        .environment(self.settings)
        .windowIdealSize(.fitToContent)
        .windowResizability(.contentSize)
    }
}
