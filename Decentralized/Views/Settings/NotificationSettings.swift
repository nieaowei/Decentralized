//
//  NotificationSettings.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/17.
//

import Combine
import SwiftUI
import UserNotifications

struct NotificationSettings: View {
    @Environment(AppSettings.self) private var settings: AppSettings

    @State var checkTask: Date = .init()
    private var timer: Publishers.Autoconnect<Timer.TimerPublisher>

    private var enableNewTx: Binding<Bool> {
        Binding(
            get: { settings.enableNotificationNewTx },
            set: { newValue in
                settings.enableNotificationNewTx = newValue
            }
        )
    }

    private var enableRemovedTx: Binding<Bool> {
        Binding(
            get: { settings.enableNotificationRemovedTx },
            set: { newValue in
                settings.enableNotificationRemovedTx = newValue
            }
        )
    }

    private var enableConfirmedTx: Binding<Bool> {
        Binding(
            get: { settings.enableNotificationConfirmedTx },
            set: { newValue in
                settings.enableNotificationConfirmedTx = newValue
            }
        )
    }

    init() {
        self.timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    }

    var body: some View {
        VStack {
            Form {
                LabeledContent("Notification") {
                    if settings.enableNotification {
                        Text("Enabled")
                    } else {
                        Text("Disabled")
                    }
                    Button {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications?id=\(Bundle.main.bundleIdentifier ?? "")") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Text(verbatim: "Open System Settings")
                    }
                }
                .onReceive(timer) { _ in
                    UNUserNotificationCenter.current().getNotificationSettings { settings in
                        let auth = (settings.authorizationStatus == .authorized)
                        Task { @MainActor in
                            self.settings.enableNotification = auth
                        }
                    }
                }

                if settings.enableNotification {
                    Section("Notification") {
                        Toggle("New Transaction", isOn: enableNewTx)
                        Toggle("Transaction Removed", isOn: enableRemovedTx)
                        Toggle("Transaction Confirmed", isOn: enableConfirmedTx)
                    }
                }
            }
            .formStyle(.grouped)
        }
    }
}
