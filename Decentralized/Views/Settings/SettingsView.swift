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
        TabView {
            Tab("Server", systemImage: "server.rack") {
                ServerSettings()
            }
            Tab("Notifaction", systemImage: "bell.badge") {
                NotificationSettings()
            }
            Tab("Wallet", systemImage: "dollarsign.circle") {
                WalletSettings()
            }
//            Tab("Safe", systemImage: "lock.shield") {
//                ServerSettings()
//            }
        }
        .scenePadding()
    }
}

struct WalletSettings: View {
    var body: some View {
        Form {
            Section {
                LabeledContent("Export Mnemonic") {
                    Button("Export Mnemonic") {}
                }
                LabeledContent("Reset Wallet") {
                    Button("Reset Wallet") {}
                }
            }
        }
        .formStyle(.grouped)
    }
}

struct ServerSettings: View {
    @Environment(AppSettings.self) var settings: AppSettings

    @State var network: Networks = .bitcoin
    @State var serverUrl: String = "https://mempool.space/api"
    @State var serverType: ServerType = .Esplora

    var body: some View {
        Form {
            Section {
                Picker(selection: $network) {
                    ForEach(Networks.allCases) { net in
                        Text(net.rawValue)
                            .tag(net)
                    }
                } label: {
                    Text("Network")
                }
                Picker("Server Type", selection: $serverType) {
                    ForEach(ServerType.allCases) { t in
                        Text(verbatim: "\(t)").tag(t)
                    }
                }
                ServerUrlPicker(selection: $serverUrl, serverType: serverType, network: network)
            }
            .sectionActions {
                Button(action: onApply) {
                    Text("Apply").padding(.horizontal)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            network = settings.network
            serverUrl = settings.serverUrl
        }
        .onChange(of: network) {
            serverUrl = staticServerUrls.first(where: { u in
                u.network == network.rawValue && u.type == serverType.rawValue
            })!.url
        }
        .onChange(of: serverType) {
            serverUrl = staticServerUrls.first(where: { u in
                u.network == network.rawValue && u.type == serverType.rawValue
            })!.url
        }
    }

    func onApply() {
        DispatchQueue.main.async{
            settings.network = network
            settings.serverUrl = serverUrl
            settings.serverType = serverType
            settings.changed = !settings.changed // ???  the update cannot be triggered without here
        }
    }
}

struct NotificationSettings: View {
    @Environment(AppSettings.self) private var settings: AppSettings

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
        }
        .formStyle(.grouped)
    }
}

struct ServerUrlPicker: View {
    @Binding var selection: String
    @Query var serverUrls: [ServerUrl]

    init(selection: Binding<String>, serverType: ServerType, network: Networks) {
        _selection = selection
        let cur = selection.wrappedValue
        _serverUrls = Query(filter: #Predicate<ServerUrl> { url in
            url.network == network.rawValue && url.type == serverType.rawValue && url.url != cur
        })
    }

    var body: some View {
        Picker("Server Url", selection: $selection) {
            // Avoid tag not exist error
            Text(selection)
                .tag(selection)
            ForEach(serverUrls) { u in
                Text(u.url)
                    .tag(u.url)
            }
//            HStack {
//                Spacer()
//                Button {} label: {
//                    Text("...Add")
//                }
//            }
        }
    }
}

// #Preview {
//    SettingsView()
// }
