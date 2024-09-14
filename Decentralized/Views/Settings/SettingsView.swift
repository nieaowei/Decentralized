//
//  SettingsView.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/28.
//

import Combine
import SwiftUI

struct SettingsView: View {
    var body: some View {
        WalletSettingsView()
    }
}

struct ServerSettings: View {
    var body: some View {
        Text("Se")
    }
}

struct WalletSettingsView: View {
//    let global: GlobalViewModel = .live
    @Environment(WalletStore.self) var wallet: WalletStore

    @Environment(AppSettings.self) private var settings: AppSettings
    @Environment(\.showError) private var showError

    @State var checkTask: Date = .init()
    private var timer: Publishers.Autoconnect<Timer.TimerPublisher>

    init() {
        self.timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    }

    var body: some View {
        Form {
            LabeledContent("Notification") {
                if settings.enableNotifiaction {
                    Text("Enabled")
                } else {
                    Button {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Text(verbatim: "Open System Settings")
                    }
                }
            }
            .onReceive(timer, perform: { tim in
                checkTask = tim
            })
            .task(id: checkTask) {
                await settings.getEnableNotifiaction()
            }

            Section {
                LabeledContent("Network", value: settings.network.rawValue)
                
                Picker("Server Type", selection: settings.$serverType) {
                    ForEach(ServerType.allCases) { t in
                        Text(verbatim: "\(t)").tag(t)
                    }
                }
                TextField("Server Url", text: settings.$serverUrl)
            }

            Section {
//                @Bindable var settings = settings
                Toggle("Touch ID", isOn: settings.$enableTouchID)
            }

            Button {
                do {
                    try wallet.delete()
                    settings.isOnBoarding = true
                } catch {
                    showError(error, "Delete")
                }
            } label: {
                Text("Reset Wallet")
            }
            .controlSize(.large)
            .buttonStyle(BorderedButtonStyle())
            .foregroundColor(.red)
        }
        .formStyle(.grouped)
        .onAppear {
            logger.info("Settings Appear")
        }
        .onDisappear {
            logger.info("Settings Disappear")
        }
    }
}

#Preview {
    SettingsView()
}
