import Photos
import UIKit

final class CacheService {
  static let shared = CacheService()

  private let thumbnailCache = NSCache<NSNumber, UIImage>()
  private let fullImageCache = NSCache<NSNumber, UIImage>()

  private init() {
    thumbnailCache.countLimit = 150
    fullImageCache.countLimit = 10
  }

  func configureCacheLimits(thumbnails: Int? = nil, fullImages: Int? = nil) {
    if let thumbnails = thumbnails {
      thumbnailCache.countLimit = thumbnails
    }
    if let fullImages = fullImages {
      fullImageCache.countLimit = fullImages
    }
  }

  func setThumbnail(_ image: UIImage, forHash hash: Int) {
    thumbnailCache.setObject(image, forKey: NSNumber(value: hash))
  }

  func getThumbnail(forHash hash: Int) -> UIImage? {
    return thumbnailCache.object(forKey: NSNumber(value: hash))
  }

  func setFullImage(_ image: UIImage, forHash hash: Int) {
    fullImageCache.setObject(image, forKey: NSNumber(value: hash))
  }

  func getFullImage(forHash hash: Int) -> UIImage? {
    return fullImageCache.object(forKey: NSNumber(value: hash))
  }

  func clearCache() {
    thumbnailCache.removeAllObjects()
    fullImageCache.removeAllObjects()
  }

  func clearThumbnailCache() {
    thumbnailCache.removeAllObjects()
  }

  func clearFullImageCache() {
    fullImageCache.removeAllObjects()
  }
}
