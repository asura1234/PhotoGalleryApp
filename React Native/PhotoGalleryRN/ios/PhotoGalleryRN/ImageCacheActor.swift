import Foundation

@globalActor
actor ImageCacheActor {
  static let shared = ImageCacheActor()

  private let imageCache = NSCache<NSString, NSData>()

  init() {
    // Configure cache limits
    imageCache.countLimit = 100  // Maximum 100 images in cache
    imageCache.totalCostLimit = 50 * 1024 * 1024  // 50MB total cache size
  }

  func getObject(for key: NSString) -> NSData? {
    return imageCache.object(forKey: key)
  }

  func setObject(_ data: NSData, for key: NSString) {
    imageCache.setObject(data, forKey: key)
  }
}
