import SwiftUI

struct PhotoCellView: View {
  @StateObject var cellState: PhotoCellViewState

  var body: some View {
    ZStack {
      Rectangle()
        .fill(Color.gray.opacity(0.3))
        .aspectRatio(1, contentMode: .fit)

      if let thumbnail = cellState.thumbnail {
        Image(uiImage: thumbnail)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .clipped()
      } else if cellState.loadFailed {
        Text("⚠️")
          .font(.system(size: 60))
      } else {
        ProgressView()
          .scaleEffect(0.8)
      }

      if cellState.loadFailed {
        VStack {
          Text("Failed to load")
            .font(.caption2)
            .foregroundColor(.white)
            .padding(4)
            .background(Color.red.opacity(0.8))
            .cornerRadius(4)
          Spacer()
        }
        .padding(4)
      }

      VStack {
        Spacer()
        HStack {
          Spacer()
          Image(systemName: cellState.isFavorite ? "heart.fill" : "heart")
            .foregroundColor(cellState.isFavorite ? .red : .white)
            .font(.caption)
            .padding(4)
            .background(Color.black.opacity(0.6))
            .clipShape(Circle())
        }
        .padding(4)
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}
