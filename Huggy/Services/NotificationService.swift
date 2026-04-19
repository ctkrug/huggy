import Foundation
import UIKit
import UserNotifications
import FirebaseAuth
import FirebaseMessaging

final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var pendingHugId: String?

    override private init() {
        super.init()
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        UNUserNotificationCenter.current().delegate = self
    }

    func saveFCMToken() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Messaging.messaging().token { token, _ in
            guard let token else { return }
            Task {
                try? await FirebaseService.shared.updateFCMToken(uid: uid, token: token)
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let hugId = userInfo["hugId"] as? String {
            DispatchQueue.main.async {
                self.pendingHugId = hugId
            }
        }
        completionHandler()
    }
}

// MARK: - MessagingDelegate

extension NotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Task {
            try? await FirebaseService.shared.updateFCMToken(uid: uid, token: fcmToken)
        }
    }
}
