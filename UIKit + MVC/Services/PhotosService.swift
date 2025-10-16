import Photos
import UIKit

enum PhotosServiceError: Error {
  case imageNotFound
  case loadingFailed
  case cacheError
  case permissionDenied
}

final class PhotosService {
  static let shared = PhotosService()

  private let cacheService = CacheService.shared

  private init() {}

  func fetchPhotos(startIndex: Int, batchSize: Int, completion: @escaping ([PHAsset]) -> Void) {
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

    let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
    let endIndex = min(startIndex + batchSize, result.count)

    guard startIndex < result.count else {
      completion([])
      return
    }

    let indexSet = IndexSet(integersIn: startIndex..<endIndex)
    let photoAssets = result.objects(at: indexSet)
    completion(photoAssets)
  }

  func getTotalPhotoCount() -> Int {
    let fetchOptions = PHFetchOptions()
    fetchOptions.fetchLimit = 0  // Don't fetch any assets, just count
    let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
    return assets.count
  }

  func fetchThumbnail(
    for asset: PHAsset, targetSize: CGSize,
    completion: @escaping (Result<UIImage, PhotosServiceError>) -> Void
  ) {
    // Create efficient hash-based cache key
    let cacheHash = "\(asset.localIdentifier)_thumbnail".hashValue

    // Check cache first
    if let cachedThumbnail = cacheService.getThumbnail(forHash: cacheHash) {
      completion(.success(cachedThumbnail))
      return
    }
    let imageManager = PHImageManager.default()
    let requestOptions = PHImageRequestOptions()
    requestOptions.isSynchronous = false
    requestOptions.deliveryMode = .fastFormat
    requestOptions.resizeMode = .exact

    imageManager.requestImage(
      for: asset,
      targetSize: targetSize,
      contentMode: .aspectFill,
      options: requestOptions
    ) { [weak self] image, info in
      if let image = image {
        // Cache the thumbnail
        self?.cacheService.setThumbnail(image, forHash: cacheHash)
        completion(.success(image))
      } else {
        // Check if there was an error in the info dictionary
        if let error = info?[PHImageErrorKey] as? Error {
          completion(.failure(.loadingFailed))
        } else if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
          completion(.failure(.loadingFailed))
        } else {
          completion(.failure(.imageNotFound))
        }
      }
    }
  }

  func fetchFullImage(
    for asset: PHAsset, completion: @escaping (Result<UIImage, PhotosServiceError>) -> Void
  ) {
    // Create efficient hash-based cache key
    let cacheHash = "\(asset.localIdentifier)_full".hashValue

    // Check cache first
    if let cachedImage = cacheService.getFullImage(forHash: cacheHash) {
      completion(.success(cachedImage))
      return
    }

    // Not in cache, fetch from photo library
    let imageManager = PHImageManager.default()
    let requestOptions = PHImageRequestOptions()
    requestOptions.isSynchronous = false
    requestOptions.deliveryMode = .highQualityFormat
    requestOptions.isNetworkAccessAllowed = true

    imageManager.requestImage(
      for: asset,
      targetSize: PHImageManagerMaximumSize,
      contentMode: .aspectFit,
      options: requestOptions
    ) { [weak self] image, info in
      if let image = image {
        // Cache the full image
        self?.cacheService.setFullImage(image, forHash: cacheHash)
        completion(.success(image))
      } else {
        // Check if there was an error in the info dictionary
        if let error = info?[PHImageErrorKey] as? Error {
          completion(.failure(.loadingFailed))
        } else if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
          completion(.failure(.loadingFailed))
        } else {
          completion(.failure(.imageNotFound))
        }
      }
    }
  }
}
