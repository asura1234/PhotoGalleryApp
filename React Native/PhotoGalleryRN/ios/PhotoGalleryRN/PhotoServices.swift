import Foundation
import Photos
import UIKit

enum PhotoServiceError: Error, LocalizedError {
  case assetNotFound(String)
  case imageFetchFailed(String)
  case invalidAssetId(String)

  var errorDescription: String? {
    switch self {
    case .assetNotFound(let id):
      return "Asset not found: \(id)"
    case .imageFetchFailed(let reason):
      return "Image fetch failed: \(reason)"
    case .invalidAssetId(let id):
      return "Invalid asset ID: \(id)"
    }
  }
}

class PhotoServices {
  static let shared = PhotoServices()
  private let imageManager = PHImageManager.default()

  private init() {}

  var canLoadMore: Bool {
    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    return status == .authorized || status == .limited
  }

  func fetchImage(
    assetId: String,
    type: ImageType,
    width: Int = 200,
    height: Int = 200
  ) async throws -> Data {

    // Fetch from Photos framework
    guard let asset = await fetchAsset(localIdentifier: assetId) else {
      throw PhotoServiceError.assetNotFound(assetId)
    }

    let requestOptions = PHImageRequestOptions()
    requestOptions.isSynchronous = false
    requestOptions.deliveryMode = .highQualityFormat
    requestOptions.isNetworkAccessAllowed = true

    do {
      switch type {
      case .thumbnail:
        // For thumbnails, request image and convert to JPEG data
        let targetSize = CGSize(width: width, height: height)
        return try await withCheckedThrowingContinuation { continuation in
          imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: requestOptions
          ) { image, info in
            if let error = info?[PHImageErrorKey] as? Error {
              continuation.resume(
                throwing: PhotoServiceError.imageFetchFailed(error.localizedDescription))
            } else if let image = image {
              if let imageData = image.jpegData(compressionQuality: 0.8) {
                continuation.resume(returning: imageData)
              } else {
                continuation.resume(
                  throwing: PhotoServiceError.imageFetchFailed("Failed to convert image to JPEG"))
              }
            } else {
              continuation.resume(
                throwing: PhotoServiceError.imageFetchFailed("No image data received"))
            }
          }
        }
      case .fullsize:
        // For full size, request original image data
        return try await withCheckedThrowingContinuation { continuation in
          imageManager.requestImageDataAndOrientation(for: asset, options: requestOptions) {
            data, _, _, info in
            if let error = info?[PHImageErrorKey] as? Error {
              continuation.resume(
                throwing: PhotoServiceError.imageFetchFailed(error.localizedDescription))
            } else if let data = data {
              continuation.resume(returning: data)
            } else {
              continuation.resume(
                throwing: PhotoServiceError.imageFetchFailed("No image data received"))
            }
          }
        }
      }
    } catch {
      throw PhotoServiceError.imageFetchFailed(error.localizedDescription)
    }
  }

  func fetchAsset(localIdentifier: String) async -> PHAsset? {
    let fetchOptions = PHFetchOptions()
    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: fetchOptions)
    return assets.firstObject
  }

  func fetchMetadata(for asset: PHAsset) async -> PhotoMetadata {
    let location = asset.location
    let creationDate = asset.creationDate ?? Date()

    // Get image data to calculate file size
    let resources = PHAssetResource.assetResources(for: asset)
    var fileSize: Int64 = 0

    if let resource = resources.first {
      if let size = resource.value(forKey: "fileSize") as? Int64 {
        fileSize = size
      }
    }

    return PhotoMetadata(
      width: Int(asset.pixelWidth),
      height: Int(asset.pixelHeight),
      created_date: creationDate,
      file_size: fileSize > 0
        ? ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file) : nil,
      location: location != nil
        ? "\(location!.coordinate.latitude), \(location!.coordinate.longitude)" : nil
    )
  }

  func fetchPhotosMetadataJSON(offset: Int = 0, limit: Int = 50) async throws -> PhotosResponse {
    // Check if we can load more - return silent failure if not
    guard canLoadMore else {
      return PhotosResponse(
        photos: [],
        total_count: 0,
        has_more: false
      )
    }

    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

    let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
    let totalCount = allPhotos.count

    // Validate bounds
    guard offset >= 0 else {
      throw PhotoServiceError.invalidAssetId("Offset must be non-negative")
    }

    guard offset < totalCount else {
      throw PhotoServiceError.invalidAssetId("Offset \(offset) exceeds total count \(totalCount)")
    }

    guard limit > 0 && limit <= 1000 else {
      throw PhotoServiceError.invalidAssetId("Limit must be between 1 and 1000")
    }

    var photos: [PhotoItem] = []
    let endIndex = min(offset + limit, totalCount)

    for i in offset..<endIndex {
      let asset = allPhotos.object(at: i)
      let metadata = await fetchMetadata(for: asset)

      let photo = PhotoItem(
        assetId: asset.localIdentifier,
        thumbnail_url: LocalURLBuilder.buildURL(for: asset.localIdentifier, type: .thumbnail),
        image_url: LocalURLBuilder.buildURL(for: asset.localIdentifier, type: .fullsize),
        metadata: metadata
      )

      photos.append(photo)
    }

    return PhotosResponse(
      photos: photos,
      total_count: totalCount,
      has_more: endIndex < totalCount
    )
  }
}

struct PhotoItem: Codable {
  let assetId: String
  let thumbnail_url: String
  let image_url: String
  let metadata: PhotoMetadata
}

struct PhotoMetadata: Codable {
  let width: Int
  let height: Int
  let created_date: Date
  let file_size: String?
  let location: String?
}

struct PhotosResponse: Codable {
  let photos: [PhotoItem]
  let total_count: Int
  let has_more: Bool
}

enum ImageType: String {
  case thumbnail = "thumbnail"
  case fullsize = "fullsize"
}
