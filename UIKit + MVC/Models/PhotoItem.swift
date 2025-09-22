import Photos
import UIKit

protocol PhotoItemObserver: AnyObject {
  func photoItemDidUpdate(_ photoItem: PhotoItem, at index: Int)
}

final class PhotoItem {
  let asset: PHAsset
  private var _thumbnail: UIImage?
  private var _loadFailed: Bool = false
  private static let favoritingService = FavoritingService.shared
  private weak var observer: PhotoItemObserver?
  private var index: Int

  init(asset: PHAsset, thumbnail: UIImage?, observer: PhotoItemObserver? = nil, index: Int) {
    self.asset = asset
    self._thumbnail = thumbnail
    self.observer = observer
    self.index = index
  }

  var identifier: String {
    return asset.localIdentifier
  }

  var thumbnail: UIImage? {
    return _thumbnail
  }

  var loadFailed: Bool {
    return _loadFailed
  }

  var isFavorite: Bool {
    return Self.favoritingService.isFavorite(assetIdentifier: identifier)
  }

  func updateThumbnail(_ thumbnail: UIImage?) {
    _thumbnail = thumbnail
    _loadFailed = false
    observer?.photoItemDidUpdate(self, at: index)
  }

  func markLoadFailed() {
    _loadFailed = true
    observer?.photoItemDidUpdate(self, at: index)
  }

  func toggleFavorite() {
    Self.favoritingService.toggleFavorite(assetIdentifier: identifier)
    observer?.photoItemDidUpdate(self, at: index)
  }

  func setObserver(_ observer: PhotoItemObserver?, at index: Int) {
    self.observer = observer
    self.index = index
  }
}
