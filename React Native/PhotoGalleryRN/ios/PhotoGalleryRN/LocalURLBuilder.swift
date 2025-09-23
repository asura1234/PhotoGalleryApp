import Foundation

class LocalURLBuilder {
  private static let baseURL = "http://127.0.0.1:8080"

  static func buildURL(for assetId: String, type: ImageType) -> String {
    guard !assetId.isEmpty else {
      fatalError("Asset ID cannot be empty")
    }

    let encodedAssetId =
      assetId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? assetId

    switch type {
    case .thumbnail:
      return "\(baseURL)/image?type=thumbnail&id=\(encodedAssetId)"
    case .fullsize:
      return "\(baseURL)/image?type=fullsize&id=\(encodedAssetId)"
    }
  }
}
