import SwiftUI
import UIKit
import UserNotifications

@main
struct CarePortalSwiftUIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue

    var body: some Scene {
        WindowGroup {
            AuthRootView()
                .environment(\.locale, AppLanguage(code: languageCode).locale)
                .id(languageCode)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        OrientationController.shared.supportedOrientations
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}

final class OrientationController {
    static let shared = OrientationController()
    var supportedOrientations: UIInterfaceOrientationMask = [.portrait, .landscapeLeft, .landscapeRight]

    private init() {}

    func lock(to orientation: UIInterfaceOrientationMask) {
        supportedOrientations = orientation
        requestOrientation(orientation)
    }

    func unlock() {
        supportedOrientations = [.portrait, .landscapeLeft, .landscapeRight]
        requestOrientation(.portrait)
    }

    private func requestOrientation(_ orientation: UIInterfaceOrientationMask) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }

        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
        windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
            windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
}

private extension UIWindowScene {
    var keyWindow: UIWindow? {
        windows.first { $0.isKeyWindow }
    }
}
