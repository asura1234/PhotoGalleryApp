import Combine
import Photos
import SwiftUI

@MainActor
final class PhotoGalleryViewModel: ObservableObject {
  @Published var photoCellStates: [PhotoCellViewState] = []
  @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined

  private static let photosService = PhotosService.shared
  private static let permissionsService = PhotoPermissionsService.shared
  private let loadMoreSubject = PassthroughSubject<Void, Never>()
  private var loadMoreCancellable: AnyCancellable?
  private var permissionCancellable: AnyCancellable?

  private let batchSize = 20
  private let maxPhotosInMemory = 100  // Maximum photos to keep in memory
  private var photoStartIndex = 0  // Track the actual start index in the full photo collection
  private var lastLoadTime: TimeInterval = 0  // For scroll debouncing

  private lazy var thumbnailSize: CGSize = {
    let screenWidth = UIScreen.main.bounds.width
    let spacing: CGFloat = 2
    let itemsPerRow: CGFloat = 3
    let totalSpacing = spacing * (itemsPerRow + 1)
    let itemWidth = (screenWidth - totalSpacing) / itemsPerRow
    return CGSize(width: itemWidth, height: itemWidth)
  }()

  init() {
    requestPhotoLibraryAccess()
    setupCacheConfiguration()
    setupLoadMorePublisher()
  }

  private func setupCacheConfiguration() {
    let cacheLimit = maxPhotosInMemory + 50
    CacheService.shared.configureCacheLimits(thumbnails: cacheLimit)
  }

  var totalPhotoCount: Int {
    return Self.photosService.getTotalPhotoCount()
  }

  var canLoadMore: Bool {
    guard authorizationStatus == .authorized else { return false }
    guard photoStartIndex + photoCellStates.count < totalPhotoCount else { return false }

    let now = Date().timeIntervalSince1970
    return now - lastLoadTime > 0.5  // 500ms debounce
  }

  private func setupLoadMorePublisher() {
    loadMoreCancellable =
      loadMoreSubject
      .filter { [weak self] in
        self?.canLoadMore ?? false
      }
      .compactMap { [weak self] _ -> (Int, Int)? in
        guard let self = self else { return nil }
        let globalAssetStartIndex = self.photoStartIndex + self.photoCellStates.count
        return (globalAssetStartIndex, self.batchSize)
      }
      .flatMap { globalAssetStartIndex, batchSize in
        Self.photosService.fetchPhotos(startIndex: globalAssetStartIndex, batchSize: batchSize)
      }
      .map { assets in
        assets.map { asset in
          PhotoCellViewState(asset: asset)
        }
      }
      .handleEvents(receiveOutput: { [weak self] newStates in
        self?.appendPhotoStates(newStates)
      })
      .flatMap { newStates in
        let assets = newStates.map { $0.asset }
        return Self.photosService.fetchThumbnails(for: assets, targetSize: self.thumbnailSize)
          .compactMap { thumbnailArrayIndex, result in
            guard thumbnailArrayIndex < newStates.count else { return nil }
            return (newStates[thumbnailArrayIndex], result)
          }
      }
      .sink { cellState, result in
        switch result {
        case .success(let thumbnail):
          cellState.thumbnail = thumbnail
          cellState.loadFailed = false
        case .failure:
          cellState.thumbnail = nil
          cellState.loadFailed = true
        }
      }
  }

  func requestPhotoLibraryAccess() {
    permissionCancellable = Self.permissionsService.requestPhotoLibraryAccess()
      .sink { [weak self] status in
        self?.authorizationStatus = status
      }
  }

  private func appendPhotoStates(_ newStates: [PhotoCellViewState]) {
    // Append new photo states to local array
    photoCellStates.append(contentsOf: newStates)

    // Check if we need to remove old photos to stay within memory limit
    let localStatesToRemove = max(0, photoCellStates.count - maxPhotosInMemory)
    if localStatesToRemove > 0 {
      // Remove photos from the beginning of local array
      photoCellStates.removeFirst(localStatesToRemove)
      photoStartIndex += localStatesToRemove
    }
  }

  func loadMorePhotos() {
    guard canLoadMore else { return }

    lastLoadTime = Date().timeIntervalSince1970
    loadMoreSubject.send()
  }

  deinit {
    loadMoreCancellable?.cancel()
    permissionCancellable?.cancel()
  }
}
