//
//  ServerSettings.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/17.
//

import SwiftData
import SwiftUI

struct ServerSettings: View {
    @Environment(AppSettings.self) var settings: AppSettings

    @State var network: Networks = .bitcoin
    @State var serverType: ServerType = .Esplora
    @State var serverUrl: String = "https://mempool.space/api"
    @State var esploraUrl: String = "https://mempool.space/api"
    @State var wssUrl: String = "wss://mempool.space/api/v1/wss"
    @State var enableCpfp: Bool = false

    var body: some View {
        Form {
            Section{
                Picker(selection: $network) {
                    ForEach([Networks.bitcoin, Networks.testnet, Networks.testnet4, Networks.signet]) { net in
                        Text(net.rawValue)
                            .tag(net)
                    }
                } label: {
                    Text("Network")
                }
            }
            Section("Sync Sever") {
                Picker("Server Type", selection: $serverType) {
                    ForEach([ServerType.Esplora, ServerType.Electrum]) { t in
                        Text(verbatim: "\(t)").tag(t)
                    }
                }
                ServerUrlPicker("Server Url", selection: $serverUrl, serverType: serverType, network: network)
                ServerUrlPicker("Websocket Url", selection: $wssUrl, serverType: .EsploraWss, network: network)
            }
            
            Section("CFPF Support") {
                Toggle("Enable", isOn: $enableCpfp)
                ServerUrlPicker("Esplora Url", selection: $esploraUrl, serverType: .Esplora, network: network)
                    .disabled(!enableCpfp)
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
            wssUrl = settings.wssUrl
            esploraUrl = settings.esploraUrl
            enableCpfp = settings.enableCpfp
        }
        .onChange(of: network) {
            serverUrl = staticServerUrls.first(where: { u in
                u.network == network.rawValue && u.type == serverType.rawValue
            })!.url

            wssUrl = staticServerUrls.first(where: { u in
                u.network == network.rawValue && u.type == ServerType.EsploraWss.rawValue
            })!.url
            
            esploraUrl = staticServerUrls.first(where: { u in
                u.network == network.rawValue && u.type == ServerType.Esplora.rawValue
            })!.url
        }
        .onChange(of: serverType) {
            serverUrl = staticServerUrls.first(where: { u in
                u.network == network.rawValue && u.type == serverType.rawValue
            })!.url
        }
    }

    func onApply() {
        settings.network = network
        settings.serverUrl = serverUrl
        settings.serverType = serverType
        settings.wssUrl = wssUrl
        settings.esploraUrl = esploraUrl
        settings.enableCpfp = enableCpfp
        settings.changed = !settings.changed // ???  the update cannot be triggered without here
    }
}

struct ServerUrlPicker: View {
    let title: String
    @Binding var selection: String
    @Query var serverUrls: [ServerUrl]

    init(_ title: String, selection: Binding<String>, serverType: ServerType, network: Networks) {
        self.title = title
        _selection = selection
        let cur = selection.wrappedValue
        _serverUrls = Query(filter: #Predicate<ServerUrl> { url in
            url.network == network.rawValue && url.type == serverType.rawValue && url.url != cur
        })
    }

    var body: some View {
        Picker(title, selection: $selection) {
            // Avoid tag not exist error
            Text(selection)
                .tag(selection)
            ForEach(serverUrls) { u in
                Text(u.url)
                    .tag(u.url)
            }
        }
    }
}
