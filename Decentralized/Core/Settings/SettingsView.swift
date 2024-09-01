//
//  SettingsView.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/28.
//

import Combine
import SwiftUI

struct SettingsView: View {
    @State var settingsVM: SettingsViewModel = .init()

    var body: some View {
        WalletSettingsView(settingsVm: settingsVM)
    }
}

struct WalletSettingsView: View {
    let global: GlobalViewModel = .live

    @Bindable var settingsVm: SettingsViewModel

    @State var serverType: ServerType
    @State var checkTask: Date = .init()
    private var timer: Publishers.Autoconnect<Timer.TimerPublisher>

    init(settingsVm: SettingsViewModel) {
        self.settingsVm = settingsVm
        self.serverType = settingsVm.serverType
        self.timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    }

    var body: some View {
        Form {
            LabeledContent("Notification") {
                if settingsVm.enableNotifiaction {
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
                await settingsVm.getEnableNotifiaction()
            }

            Section {
                Picker("Server Type", selection: $serverType) {
                    ForEach(ServerType.allCases) { t in
                        Text(verbatim: "\(t)").tag(t)
                    }
                }
                .onChange(of: serverType) {
                    settingsVm.serverType = serverType
                }
                TextField("Server Url", text: settingsVm.$serverUrl)
            }
            
            Section{
                Toggle("Touch ID", isOn: .constant(false))
            }
            
            Button {
                global.delete()
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
        Form{
            
        }
       
    }
}

#Preview {
    SettingsView()
}
