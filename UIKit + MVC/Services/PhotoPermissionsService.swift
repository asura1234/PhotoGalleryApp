import Photos
import UIKit

final class PhotoPermissionsService {
  static let shared = PhotoPermissionsService()

  private init() {}

  func requestPhotoLibraryPermission(completion: @escaping (PHAuthorizationStatus) -> Void) {
    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

    if status == .notDetermined {
      PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
        completion(newStatus)
      }
    } else {
      completion(status)
    }
  }

  func getCurrentAuthorizationStatus() -> PHAuthorizationStatus {
    return PHPhotoLibrary.authorizationStatus(for: .readWrite)
  }
}
