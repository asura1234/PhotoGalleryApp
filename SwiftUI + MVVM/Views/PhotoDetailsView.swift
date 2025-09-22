import SwiftUI

struct PhotoDetailsView: View {
  @StateObject private var viewModel: PhotoDetailsViewModel
  @Environment(\.dismiss) private var dismiss

  init(photo: PhotoCellViewState) {
    self._viewModel = StateObject(wrappedValue: PhotoDetailsViewModel(photo: photo))
  }

  var body: some View {
    NavigationView {
      ZStack {
        Color.black.ignoresSafeArea()

        if viewModel.isLoading {
          ProgressView("Loading photo...")
            .foregroundColor(.white)
        } else if let errorMessage = viewModel.errorMessage {
          errorView(message: errorMessage)
        } else if let image = viewModel.fullImage {
          photoView(image: image)
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Back") {
            dismiss()
          }
          .foregroundColor(.white)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: {
            viewModel.toggleFavorite()
          }) {
            Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
              .foregroundColor(viewModel.isFavorite ? .red : .white)
          }
        }
      }
    }
  }

  private func photoView(image: UIImage) -> some View {
    Image(uiImage: image)
      .resizable()
      .aspectRatio(contentMode: .fit)
  }

  private func errorView(message: String) -> some View {
    VStack(spacing: 20) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 60))
        .foregroundColor(.red)

      Text("Error")
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundColor(.white)

      Text(message)
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)
        .padding(.horizontal)
    }
    .padding()
  }
}
