import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = ViewController() // Set initial view controller

        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light // Change to .dark to test Dark Mode
        }

        window?.makeKeyAndVisible()
        return true
    }
}
