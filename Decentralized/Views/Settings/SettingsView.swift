//
//  SettingsView.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/28.
//

import Combine
import SwiftData
import SwiftUI

struct SettingsView: View {
    var body: some View {
        WalletSettingsView()
    }
}

struct ServerSettings: View {
    var body: some View {
        Text("")
    }
}

struct WalletSettingsView: View {
    @Environment(WalletStore.self) var wallet: WalletStore

    @Environment(AppSettings.self) private var settings: AppSettings
    @Environment(\.showError) private var showError
    @Environment(\.dismissWindow) private var dismissWindow

    @Environment(\.modelContext) private var ctx

    @State var checkTask: Date = .init()
    private var timer: Publishers.Autoconnect<Timer.TimerPublisher>

    @State var isDevelopment = false

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
                LabeledContent {
                    Text(settings.network.rawValue)
                } label: {
                    Text("Network")
                        .onTapGesture(count: 5) {
                            isDevelopment = !isDevelopment
                        }
                }

                Picker("Server Type", selection: settings.$serverType) {
                    ForEach(ServerType.allCases) { t in
                        Text(verbatim: "\(t)").tag(t)
                    }
                }
                ServerUrlPicker(selection: settings.$serverUrl, network: settings.network)
            }

            Section {
                Toggle("Touch ID", isOn: settings.$enableTouchID)
            }

            HStack {
                Button(action: onReset) {
                    Text("Reset Wallet")
                }
                .controlSize(.large)
                .buttonStyle(BorderedButtonStyle())
                .foregroundColor(.red)
            }
            if isDevelopment {
                Section("Development") {
                    Toggle("First Start", isOn: settings.$isFirst)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            logger.info("Settings Appear")
        }
        .onDisappear {
            logger.info("Settings Disappear")
        }
        .onAppear {
            if settings.isFirst {
                settings.isFirst = false
                for i in staticServerUrls {
                    ctx.insert(i)
                }
                try! ctx.save()
            }
        }
    }

    func onReset() {
        do {
            try wallet.delete()
            try ctx.delete(model: Contact.self)
            settings.isOnBoarding = true
            dismissWindow()
        } catch {
            showError(error, "Delete")
        }
    }
}

struct ServerUrlPicker: View {
    @Binding var selection: String
    @Query var serverUrls: [ServerUrl]

    init(selection: Binding<String>, network: Networks) {
        _selection = selection
        _serverUrls = Query(filter: #Predicate<ServerUrl> { url in url.network == network.rawValue })
    }

    var body: some View {
        Picker("Server Url", selection: $selection) {
            ForEach(serverUrls) { u in
                Text(u.url)
                    .tag(u.url)
            }
        }
    }
}

// #Preview {
//    SettingsView()
// }
