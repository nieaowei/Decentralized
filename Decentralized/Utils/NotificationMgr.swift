//
//  NotificationMgr.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/29.
//

import SwiftUI
import UserNotifications

class NotificationManager {
    func requestAuthorization() async{
//        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
//            NSWorkspace.shared.open(url)
//        }
        do {
            let ok = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .providesAppNotificationSettings])
            if ok {
                print("Notfication granted")
            }else{
                print("Notfication failed")
            }
        }catch{
            print("Notfication error \(error)")
        } 
    }

    func sendNotification(title: String, subtitle: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = body
        content.sound = UNNotificationSound.default
        content.interruptionLevel = .timeSensitive
        // Create a trigger to fire the notification in 1 second
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)

        // Create a request with a unique identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: .none)

        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification request: \(error)")
            } else {
                print("Notification scheduled.")
            }
        }
    }
}
