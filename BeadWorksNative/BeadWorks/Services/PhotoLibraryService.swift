import Photos
import UIKit

enum PhotoLibraryServiceError: Error, Equatable {
    case denied
    case saveFailed
}

enum PhotoLibraryService {
    static func save(_ image: UIImage) async throws {
        let granted = await requestAddAccess()
        guard granted else { throw PhotoLibraryServiceError.denied }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? PhotoLibraryServiceError.saveFailed)
                }
            })
        }
    }

    private static func requestAddAccess() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            let next = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            return next == .authorized || next == .limited
        @unknown default:
            return false
        }
    }
}
