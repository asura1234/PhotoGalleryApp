import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    window = UIWindow(frame: UIScreen.main.bounds)

    let photoGalleryVC = PhotoGalleryViewController()
    let navigationController = UINavigationController(rootViewController: photoGalleryVC)

    window?.rootViewController = navigationController
    window?.makeKeyAndVisible()

    return true
  }
}
