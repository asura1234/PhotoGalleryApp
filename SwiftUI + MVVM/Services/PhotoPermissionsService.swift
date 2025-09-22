import Combine
import Photos

final class PhotoPermissionsService {
  static let shared = PhotoPermissionsService()

  private init() {}

  func getCurrentAuthorizationStatus() -> PHAuthorizationStatus {
    return PHPhotoLibrary.authorizationStatus()
  }

  func requestPhotoLibraryAccess() -> AnyPublisher<PHAuthorizationStatus, Never> {
    let currentStatus = getCurrentAuthorizationStatus()

    if currentStatus == .notDetermined {
      return Future { promise in
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
          promise(.success(status))
        }
      }
      .eraseToAnyPublisher()
    } else {
      return Just(currentStatus).eraseToAnyPublisher()
    }
  }
}
