import Photos

/// Abstracts the native photo-library permission prompt so view models can request/check access
/// without depending on `PHPhotoLibrary` directly (keeps them testable and UIKit/Photos-framework
/// free).
protocol PhotoLibraryAccessManaging {
    /// Current authorization state without prompting the user.
    var isAuthorized: Bool { get }

    /// Triggers the native "Allow access to photos?" system alert if the status hasn't been
    /// determined yet, or returns immediately if it's already known. Returns whether the app now
    /// has (at least limited) access.
    func requestAccess() async -> Bool
}

final class PhotoLibraryAccessManager: PhotoLibraryAccessManaging {
    var isAuthorized: Bool {
        Self.isGranted(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    func requestAccess() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return Self.isGranted(status)
    }

    private static func isGranted(_ status: PHAuthorizationStatus) -> Bool {
        status == .authorized || status == .limited
    }
}
