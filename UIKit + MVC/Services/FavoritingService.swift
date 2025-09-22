import Foundation

final class FavoritingService {
  static let shared = FavoritingService()

  private let userDefaults = UserDefaults.standard
  private let favoritesKey = "favorite_photos"

  // In-memory cache for O(1) lookups
  private var favoritesSet: Set<String> = []
  private var isLoaded = false

  private init() {
    loadFavorites()
  }

  func isFavorite(assetIdentifier: String) -> Bool {
    return favoritesSet.contains(assetIdentifier)
  }

  func toggleFavorite(assetIdentifier: String) {
    if favoritesSet.contains(assetIdentifier) {
      favoritesSet.remove(assetIdentifier)
    } else {
      favoritesSet.insert(assetIdentifier)
    }
    saveFavorites()
  }

  private func loadFavorites() {
    guard !isLoaded else { return }

    if let favoritesArray = userDefaults.stringArray(forKey: favoritesKey) {
      favoritesSet = Set(favoritesArray)
    } else {
      favoritesSet = Set()
    }
    isLoaded = true
  }

  private func saveFavorites() {
    let favoritesArray = Array(favoritesSet)
    userDefaults.set(favoritesArray, forKey: favoritesKey)
  }
}
