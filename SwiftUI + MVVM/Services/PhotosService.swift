import Combine
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

  private let imageManager = PHImageManager.default()
  private let cacheService = CacheService.shared

  private init() {}


  func getTotalPhotoCount() -> Int {
    let fetchOptions = PHFetchOptions()
    fetchOptions.fetchLimit = 0
    let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
    return assets.count
  }

  func fetchPhotos(startIndex: Int, batchSize: Int) -> AnyPublisher<[PHAsset], Never> {
    Future { promise in
      let fetchOptions = PHFetchOptions()
      fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

      let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
      var result: [PHAsset] = []

      let endIndex = min(startIndex + batchSize, assets.count)
      guard startIndex < assets.count else {
        promise(.success([]))
        return
      }

      for i in startIndex..<endIndex {
        result.append(assets.object(at: i))
      }
      promise(.success(result))
    }
    .eraseToAnyPublisher()
  }

  func fetchThumbnail(for asset: PHAsset, targetSize: CGSize = CGSize(width: 200, height: 200))
    -> AnyPublisher<UIImage?, Error>
  {
    // Create efficient hash-based cache key
    let cacheHash = asset.localIdentifier.hashValue

    if let cachedImage = cacheService.getThumbnail(forHash: cacheHash) {
      return Just(cachedImage)
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }

    return Future { promise in
      let requestOptions = PHImageRequestOptions()
      requestOptions.isSynchronous = false
      requestOptions.deliveryMode = .fastFormat
      requestOptions.resizeMode = .exact

      self.imageManager.requestImage(
        for: asset,
        targetSize: targetSize,
        contentMode: .aspectFill,
        options: requestOptions
      ) { image, info in
        if let error = info?[PHImageErrorKey] as? Error {
          promise(.failure(error))
        } else if let image = image {
          self.cacheService.setThumbnail(image, forHash: cacheHash)
          promise(.success(image))
        } else {
          promise(.success(nil))
        }
      }
    }
    .eraseToAnyPublisher()
  }


  func fetchThumbnails(for assets: [PHAsset], targetSize: CGSize = CGSize(width: 200, height: 200))
    -> AnyPublisher<(Int, Result<UIImage, Error>), Never>
  {
    let thumbnailRequests = assets.enumerated().map { index, asset in
      fetchThumbnail(for: asset, targetSize: targetSize)
        .map { thumbnail in (index, Result<UIImage, Error>.success(thumbnail)) }
        .catch { error in Just((index, Result<UIImage, Error>.failure(error))) }
    }

    return Publishers.MergeMany(thumbnailRequests)
      .eraseToAnyPublisher()
  }

  func fetchFullImage(for asset: PHAsset) -> AnyPublisher<UIImage?, Error> {
    // Create efficient hash-based cache key
    let cacheHash = asset.localIdentifier.hashValue

    if let cachedImage = cacheService.getFullImage(forHash: cacheHash) {
      return Just(cachedImage)
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }

    let screenSize = UIScreen.main.bounds.size
    let targetSize = CGSize(
      width: screenSize.width * UIScreen.main.scale, height: screenSize.height * UIScreen.main.scale
    )

    return Future { promise in
      let requestOptions = PHImageRequestOptions()
      requestOptions.isSynchronous = false
      requestOptions.deliveryMode = .highQualityFormat
      requestOptions.resizeMode = .exact

      self.imageManager.requestImage(
        for: asset,
        targetSize: targetSize,
        contentMode: .aspectFit,
        options: requestOptions
      ) { image, info in
        if let error = info?[PHImageErrorKey] as? Error {
          promise(.failure(error))
        } else if let image = image {
          self.cacheService.setFullImage(image, forHash: cacheHash)
          promise(.success(image))
        } else {
          promise(.success(nil))
        }
      }
    }
    .eraseToAnyPublisher()
  }
}
