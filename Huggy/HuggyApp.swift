import SwiftUI
import FirebaseCore
import FirebaseMessaging

@main
struct HuggyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var hugVM = HugViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authVM)
                .environmentObject(hugVM)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onReceive(NotificationService.shared.$pendingHugId) { hugId in
                    guard let hugId else { return }
                    Task {
                        await hugVM.handleReceivedHug(hugId: hugId)
                        NotificationService.shared.pendingHugId = nil
                    }
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        // Parse token from huggy.page.link/invite?token=xxx
        // or huggy://invite?token=xxx
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value else {
            return
        }
        Task {
            await hugVM.acceptInvite(token: token)
        }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = NotificationService.shared
        NotificationService.shared.requestPermission()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
}
