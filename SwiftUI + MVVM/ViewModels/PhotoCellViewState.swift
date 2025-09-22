import Foundation
import SwiftUI
import Photos

@MainActor
final class PhotoCellViewState: ObservableObject, Identifiable {
  let asset: PHAsset
  @Published var thumbnail: UIImage?
  @Published var isFavorite: Bool
  @Published var loadFailed = false

  private static let favoritingService = FavoritingService.shared

  init(asset: PHAsset, thumbnail: UIImage? = nil) {
    self.asset = asset
    self.thumbnail = thumbnail
    self.isFavorite = Self.favoritingService.isFavorite(assetIdentifier: asset.localIdentifier)
  }

  var id: String {
    return asset.localIdentifier
  }

  func toggleFavorite() {
    isFavorite.toggle()
    Self.favoritingService.toggleFavorite(assetIdentifier: id)
  }
}