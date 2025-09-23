import Foundation
import Photos
import React

@objc(PhotoPermissionsService)
class PhotoPermissionsService: NSObject {

  @objc
  static func requiresMainQueueSetup() -> Bool {
    return false
  }

  @objc
  func checkOrRequestPermissionWhenNeeded(
    _ resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
    let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

    switch currentStatus {
    case .authorized, .limited:
      resolve(true)
    case .denied, .restricted:
      resolve(false)
    case .notDetermined:
      PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
        DispatchQueue.main.async {
          switch status {
          case .authorized, .limited:
            resolve(true)
          default:
            resolve(false)
          }
        }
      }
    @unknown default:
      resolve(false)
    }
  }
}