import Photos
import SwiftUI

struct PhotoGalleryView: View {
  @StateObject private var viewModel = PhotoGalleryViewModel()
  @State private var scrollPosition: Int?

  private let columns = [
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible()),
  ]

  var body: some View {
    NavigationView {
      Group {
        if viewModel.authorizationStatus == .denied || viewModel.authorizationStatus == .restricted
        {
          permissionDeniedView
        } else {
          photoGridView
        }
      }
      .navigationTitle("Photos")
      .navigationBarTitleDisplayMode(.large)
    }
  }

  private var photoGridView: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 2) {
        ForEach(viewModel.photoCellStates, id: \.id) { cellState in
          NavigationLink(destination: PhotoDetailsView(photo: cellState)) {
            PhotoCellView(cellState: cellState)
          }
        }
      }
      .padding(.horizontal, 2)
    }
    .scrollPosition(id: $scrollPosition)
    .onChange(of: scrollPosition) { _, _ in
      viewModel.loadMorePhotos()
    }
    .onAppear {
      viewModel.loadMorePhotos()
    }
  }

  private var permissionDeniedView: some View {
    VStack(spacing: 20) {
      Image(systemName: "photo.on.rectangle")
        .font(.system(size: 60))
        .foregroundColor(.gray)

      Text("Photo Access Required")
        .font(.title2)
        .fontWeight(.semibold)

      Text("Please allow access to your photo library in Settings to view your photos.")
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)
        .padding(.horizontal)

      Button("Open Settings") {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(settingsURL)
        }
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
  }

}
