//
//  NotificationSettings.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/17.
//


import SwiftUI
import Combine

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
