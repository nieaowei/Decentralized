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
        completionHandler()
    }
}

@main
struct DecentralizedApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate

    @AppStorage("isOnBoarding") var isOnBoarding: Bool = true
    @Environment(\.openWindow) private var openWindow

    let settings: AppSettings
    let mainModelContainer: ModelContainer = try! ModelContainer(for: Contact.self, ServerUrl.self, CpfpChain.self, configurations: ModelConfiguration())

    @State private var errorWrapper: ErrorWrapper?

    init() {
        let settings = AppSettings()
        logger.info("App Init \(settings.serverUrl)")
        self.settings = settings
    }

    var body: some Scene {
        WindowGroup {
            if isOnBoarding {
                OnBoradingView()
                    .tint(settings.accentColor)
                    .toolbar(removing: .title)
                    .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                    .containerBackground(.thickMaterial, for: .window)
                    .windowMinimizeBehavior(.disabled)
                    .windowResizeBehavior(.disabled)
                    .sheet(item: $errorWrapper) { errorWrapper in
                        Text(errorWrapper.error.localizedDescription)
                    }

            } else {
                HomeView(settings)
                    .tint(settings.accentColor)
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
        .environment(settings)
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

        Window("Welcome", id: "welcom") {
            OnBoradingView()
                .toolbar(removing: .title)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                .containerBackground(.thickMaterial, for: .window)
                .windowMinimizeBehavior(.disabled)
                .windowResizeBehavior(.disabled)
                .sheet(item: $errorWrapper) { errorWrapper in
                    Text(errorWrapper.error.localizedDescription)
                }
        }
        .environment(settings)

        // Custom About
        Window("About", id: "about") {
            AboutView()
                .toolbar(removing: .title)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                .containerBackground(.thickMaterial, for: .window)
                .windowMinimizeBehavior(.disabled)
                .windowResizeBehavior(.disabled)
                .tint(settings.accentColor)
        }
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
        .commandsRemoved()

        Settings {
            SettingsView()
                .windowResizeBehavior(.enabled)
                .modelContainer(mainModelContainer)
                .tint(settings.accentColor)
        }
        .environment(settings)
        .windowIdealSize(.fitToContent)
        .windowResizability(.contentSize)
    }
}
