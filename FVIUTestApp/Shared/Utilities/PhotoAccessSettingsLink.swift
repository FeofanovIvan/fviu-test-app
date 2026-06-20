import UIKit

/// Opens the app's page in the iOS Settings app — the only way forward once the user has denied
/// photo-library access, since `PHPhotoLibrary` won't show its own permission dialog a second time.
enum PhotoAccessSettingsLink {
    static func open() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
