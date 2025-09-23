import Foundation
import Photos
import React

@objc(PhotosServiceNativeModule)
class PhotosServiceNativeModule: NSObject {

  @objc
  static func requiresMainQueueSetup() -> Bool {
    return false
  }

  override init() {
    super.init()
    // Start the async HTTP server when the module is initialized
    Task {
      do {
        try await AsyncImageServer.shared.startServer()
        print("Async Image Server started successfully")
      } catch {
        print("Failed to start Async Image Server: \(error)")
      }
    }
  }

  deinit {
    // Stop the HTTP server when the module is deallocated
    Task {
      await AsyncImageServer.shared.stopServer()
    }
  }

  @objc
  func getPhotos(
    _ startIndex: NSNumber,
    batchSize: NSNumber,
    resolver resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
    let start = startIndex.intValue
    let limit = batchSize.intValue

    // Validate input parameters
    guard start >= 0 else {
      reject("INVALID_PARAMS", "Start index must be non-negative", nil)
      return
    }

    guard limit > 0 && limit <= 1000 else {
      reject("INVALID_PARAMS", "Batch size must be between 1 and 1000", nil)
      return
    }

    Task {
      do {
        let photosResponse = try await PhotoServices.shared.fetchPhotosMetadataJSON(
          offset: start,
          limit: limit
        )

        let responseDict: [String: Any] = [
          "photos": photosResponse.photos.map { photo in
            return [
              "assetId": photo.assetId,
              "thumbnail_url": photo.thumbnail_url,
              "image_url": photo.image_url,
              "metadata": [
                "width": photo.metadata.width,
                "height": photo.metadata.height,
                "created_date": ISO8601DateFormatter().string(from: photo.metadata.created_date),
                "file_size": photo.metadata.file_size as Any,
                "location": photo.metadata.location as Any,
              ],
            ]
          },
          "total_count": photosResponse.total_count,
          "has_more": photosResponse.has_more,
        ]

        DispatchQueue.main.async {
          resolve(responseDict)
        }
      } catch {
        DispatchQueue.main.async {
          reject("FETCH_ERROR", "Failed to fetch photos", error)
        }
      }
    }
  }
}
