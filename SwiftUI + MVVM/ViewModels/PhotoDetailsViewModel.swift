import Combine
import Photos
import SwiftUI

@MainActor
final class PhotoDetailsViewModel: ObservableObject {
  @Published var fullImage: UIImage?
  @Published var isLoading = true
  @Published var errorMessage: String? = nil

  private let photo: PhotoCellViewState
  private static let photosService = PhotosService.shared
  private var loadImageCancellable: AnyCancellable?

  init(photo: PhotoCellViewState) {
    self.photo = photo
    loadFullImage()
  }

  var isFavorite: Bool {
    return photo.isFavorite
  }

  func toggleFavorite() {
    photo.toggleFavorite()
  }

  func loadFullImage() {
    isLoading = true
    errorMessage = nil

    loadImageCancellable = Self.photosService.fetchFullImage(for: photo.asset)
      .subscribe(on: DispatchQueue.global())
      .receive(on: DispatchQueue.main)
      .sink(
        receiveCompletion: { [weak self] completion in
          guard let self = self else { return }
          self.isLoading = false
          if case .failure = completion {
            self.errorMessage = "Failed to load the photo. Please try again."
          }
        },
        receiveValue: { [weak self] image in
          guard let self = self else { return }
          self.fullImage = image
        }
      )
  }

  deinit {
    loadImageCancellable?.cancel()
  }
}
