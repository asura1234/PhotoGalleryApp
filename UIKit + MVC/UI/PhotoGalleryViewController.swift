import Photos
import UIKit

final class PhotoGalleryViewController: UIViewController, PhotoItemObserver {

  static let photosService = PhotosService.shared
  static let permissionsService = PhotoPermissionsService.shared

  private let collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.minimumInteritemSpacing = 2
    layout.minimumLineSpacing = 2
    layout.sectionInset = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)

    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .systemBackground
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    return collectionView
  }()

  private let permissionDeniedLabel: UILabel = {
    let label = UILabel()
    label.text = "Photo library access is required to view your photos."
    label.textAlignment = .center
    label.numberOfLines = 0
    label.textColor = .secondaryLabel
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isHidden = true
    return label
  }()

  private let settingsButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("Open Settings", for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.isHidden = true
    return button
  }()

  private lazy var thumbnailSize: CGSize = {
    let screenWidth = UIScreen.main.bounds.width
    let spacing: CGFloat = 2
    let itemsPerRow: CGFloat = 3
    let totalSpacing = spacing * (itemsPerRow + 1)
    let itemWidth = (screenWidth - totalSpacing) / itemsPerRow
    return CGSize(width: itemWidth, height: itemWidth)
  }()

  private var photos: [PhotoItem] = []
  private var photoStartIndex = 0  // Track the actual start index in the full photo collection
  private let maxPhotosInMemory = 100  // Maximum photos to keep in memory
  private var lastLoadTime: TimeInterval = 0  // For scroll debouncing
  private var isLoading = false  // Prevent overlapping load requests
  private var authorizationStatus: PHAuthorizationStatus = .notDetermined
  private var totalPhotoCount: Int {
    return Self.photosService.getTotalPhotoCount()
  }

  private var canLoadMore: Bool {
    guard authorizationStatus == .authorized else { return false }
    guard !isLoading else { return false }
    guard photoStartIndex + photos.count < totalPhotoCount else { return false }

    let now = Date().timeIntervalSince1970
    return now - lastLoadTime > 0.5  // 500ms debounce
  }

  private let batchSize = 20

  override func viewDidLoad() {
    super.viewDidLoad()
    requestPhotoLibraryAccess()
    setupUI()
    setupCacheConfiguration()
  }

  private func setupCacheConfiguration() {
    // Set cache limits to handle sliding window + buffer
    let cacheLimit = maxPhotosInMemory + 50
    CacheService.shared.configureCacheLimits(thumbnails: cacheLimit)
  }

  private func setupUI() {
    view.backgroundColor = .systemBackground
    title = "Photos"

    view.addSubview(collectionView)
    view.addSubview(permissionDeniedLabel)
    view.addSubview(settingsButton)

    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      permissionDeniedLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      permissionDeniedLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      permissionDeniedLabel.leadingAnchor.constraint(
        greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
      permissionDeniedLabel.trailingAnchor.constraint(
        lessThanOrEqualTo: view.trailingAnchor, constant: -20),

      settingsButton.topAnchor.constraint(
        equalTo: permissionDeniedLabel.bottomAnchor, constant: 20),
      settingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
    ])

    settingsButton.addAction(
      UIAction { [weak self] _ in
        self?.handleSettingsButtonTap()
      }, for: .touchUpInside)

    // Setup collection view
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.identifier)
  }

  private func requestPhotoLibraryAccess() {
    let currentStatus = Self.permissionsService.getCurrentAuthorizationStatus()

    if currentStatus == .notDetermined {
      Self.permissionsService.requestPhotoLibraryPermission { [weak self] status in
        self?.handlePermissionStatus(status)
      }
    } else {
      handlePermissionStatus(currentStatus)
    }
  }

  private func handlePermissionStatus(_ status: PHAuthorizationStatus) {
    authorizationStatus = status

    switch status {
    case .authorized, .limited:
      loadMorePhotos()
    case .denied, .restricted:
      showPermissionDeniedUI()
    case .notDetermined:
      assertionFailure("notDetermined should be handled in requestPhotoLibraryAccess")
    @unknown default:
      showPermissionDeniedUI()
    }
  }

  private func loadMorePhotos() {
    guard canLoadMore else { return }

    lastLoadTime = Date().timeIntervalSince1970
    isLoading = true

    loadPhotosBatch { [weak self] items in
      guard let self = self else { return }
      self.appendPhotos(items)
      self.loadThumbnailsForPhotos(photos: items) { [weak self] in
        self?.isLoading = false
      }
    }
  }

  private func loadPhotosBatch(completion: @escaping ([PhotoItem]) -> Void) {
    let globalStartIndex = photoStartIndex + photos.count

    Self.photosService.fetchPhotos(startIndex: globalStartIndex, batchSize: batchSize) {
      [weak self] assets in
      guard let self = self else { return }
      let newPhotos = assets.enumerated().map { index, asset in
        PhotoItem(asset: asset, thumbnail: nil, observer: self, index: globalStartIndex + index)
      }
      completion(newPhotos)
    }
  }

  private func loadThumbnailsForPhotos(
    photos: [PhotoItem], completion: (@escaping () -> Void)? = nil
  ) {
    let dispatchGroup = DispatchGroup()

    for photo in photos {
      dispatchGroup.enter()
      Self.photosService.fetchThumbnail(for: photo.asset, targetSize: thumbnailSize) { result in
        switch result {
        case .success(let thumbnail):
          photo.updateThumbnail(thumbnail)
        case .failure(_):
          photo.markLoadFailed()
        }
        dispatchGroup.leave()
      }
    }

    dispatchGroup.notify(queue: .main) {
      completion?()
    }
  }

  private func appendPhotos(_ newPhotos: [PhotoItem]) {
    DispatchQueue.main.async {
      if self.photos.isEmpty {
        // First batch - replace all
        self.photos = newPhotos
        self.collectionView.reloadData()
      } else {
        // Subsequent batches - append
        let localInsertIndex = self.photos.count
        self.photos.append(contentsOf: newPhotos)

        // Check if we need to remove old photos to stay within memory limit
        let photosToRemove = max(0, self.photos.count - self.maxPhotosInMemory)
        if photosToRemove > 0 {
          // Remove photos from the beginning
          self.photos.removeFirst(photosToRemove)
          self.photoStartIndex += photosToRemove

          // Remove corresponding collection view items
          let indexPathsToRemove = (0..<photosToRemove).map { IndexPath(item: $0, section: 0) }
          self.collectionView.deleteItems(at: indexPathsToRemove)

          // Update observer indices for remaining photos
          self.updatePhotoObserverIndices()
        }

        // Insert new cells with animation
        let localStartIndexForNewPhotos = self.photos.count - newPhotos.count
        let indexPaths = (localStartIndexForNewPhotos..<self.photos.count).map {
          IndexPath(item: $0, section: 0)
        }
        self.collectionView.insertItems(at: indexPaths)
      }
    }
  }

  private func showPermissionDeniedUI() {
    DispatchQueue.main.async {
      self.permissionDeniedLabel.isHidden = false
      self.settingsButton.isHidden = false
      self.collectionView.isHidden = true
    }
  }

  private func handleSettingsButtonTap() {
    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(settingsURL)
    }
  }
}

extension PhotoGalleryViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
    -> Int
  {
    return photos.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
    -> UICollectionViewCell
  {
    let cell =
      collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.identifier, for: indexPath)
      as! PhotoCell
    cell.configure(with: photos[indexPath.item])
    return cell
  }
}

extension PhotoGalleryViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let photo = photos[indexPath.item]
    let detailVC = PhotoDetailsViewController(photo: photo)
    let navController = UINavigationController(rootViewController: detailVC)
    present(navController, animated: true)
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    loadMorePhotos()
  }
}

extension PhotoGalleryViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(
    _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    return thumbnailSize
  }
}

extension PhotoGalleryViewController: PhotoItemObserver {
  func photoItemDidUpdate(_ photoItem: PhotoItem, at globalIndex: Int) {
    DispatchQueue.main.async {
      // Convert global index to local array index
      let localIndex = globalIndex - self.photoStartIndex
      guard localIndex >= 0 && localIndex < self.photos.count else { return }

      if let cell = self.collectionView.cellForItem(at: IndexPath(item: localIndex, section: 0))
        as? PhotoCell
      {
        cell.configure(with: self.photos[localIndex])
      }
    }
  }

  private func updatePhotoObserverIndices() {
    for (localIndex, photo) in photos.enumerated() {
      let globalIndex = photoStartIndex + localIndex
      photo.setObserver(self, at: globalIndex)
    }
  }
}
