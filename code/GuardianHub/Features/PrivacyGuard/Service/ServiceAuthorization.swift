#if os(iOS)

import Foundation
import Photos

enum PhotosAuthorizationError: LocalizedError {
    case denied
    case restricted

    var errorDescription: String? {
        switch self {
        case .denied:
            return "Photo access was denied. Please enable it in Settings to export stripped photos."
        case .restricted:
            return "Photo access is restricted on this device."
        }
    }
}

struct PhotosAuthorization {
    /// Ensures we have permission to read photo library assets (needed to reload original data via PHAsset).
    static func ensureAuthorized() async throws {
        let current = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch current {
        case .authorized, .limited:
            return
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            switch newStatus {
            case .authorized, .limited:
                return
            case .denied:
                throw PhotosAuthorizationError.denied
            case .restricted:
                throw PhotosAuthorizationError.restricted
            default:
                throw PhotosAuthorizationError.denied
            }
        case .denied:
            throw PhotosAuthorizationError.denied
        case .restricted:
            throw PhotosAuthorizationError.restricted
        @unknown default:
            throw PhotosAuthorizationError.denied
        }
    }
}

#endif
