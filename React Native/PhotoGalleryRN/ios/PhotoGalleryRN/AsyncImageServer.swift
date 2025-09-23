import Foundation
import Photos
import UIKit
import Vapor

class AsyncImageServer {
  static let shared = AsyncImageServer()
  private var app: Application?
  private let port: Int = 8080

  private init() {}

  func startServer() async throws {
    // Create Vapor app
    let app = Application(.production)
    self.app = app

    // Configure server for concurrency
    app.http.server.configuration.hostname = "127.0.0.1"
    app.http.server.configuration.port = port
    app.http.server.configuration.backlog = 256  // Allow more concurrent connections
    app.http.server.configuration.reuseAddress = true
    app.http.server.configuration.tcpNoDelay = true

    // Setup routes
    setupRoutes(app: app)

    // Start server
    try await app.run()
  }

  func stopServer() {
    app?.shutdown()
    app = nil
    print("Async Image Server stopped")
  }

  private func setupRoutes(app: Application) {
    // GET /image - Serve image with async support
    app.get("image") { req async throws -> Response in
      guard let assetId = req.query[String.self, at: "id"],
        let typeString = req.query[String.self, at: "type"],
        let type = ImageType(rawValue: typeString)
      else {
        return Response(status: .badRequest, body: .init(string: "Missing or invalid parameters"))
      }

      // Validate asset ID
      guard !assetId.isEmpty else {
        return Response(status: .badRequest, body: .init(string: "Asset ID cannot be empty"))
      }

      let width = req.query[Int.self, at: "width"] ?? 200
      let height = req.query[Int.self, at: "height"] ?? 200

      // Validate dimensions
      guard width > 0 && width <= 4096 && height > 0 && height <= 4096 else {
        return Response(
          status: .badRequest,
          body: .init(string: "Invalid dimensions. Width and height must be between 1 and 4096"))
      }

      // Create cache key
      let cacheKey = "\(assetId)_\(type.rawValue)_\(width)_\(height)" as NSString

      // Check cache first
      if let cachedData = await ImageCacheActor.shared.getObject(for: cacheKey) {
        var response = Response(status: .ok, body: .init(data: cachedData as Data))
        response.headers.add(name: "Content-Type", value: "image/jpeg")
        response.headers.add(name: "Cache-Control", value: "public, max-age=3600")
        response.headers.add(name: "X-Cache", value: "HIT")
        return response
      }

      // Fetch image asynchronously
      do {
        let imageData = try await PhotoServices.shared.fetchImage(
          assetId: assetId,
          type: type,
          width: width,
          height: height
        )

        guard let imageData = imageData else {
          return Response(status: .notFound, body: .init(string: "Image not found"))
        }

        // Cache the image data
        await ImageCacheActor.shared.setObject(imageData as NSData, for: cacheKey)

        var response = Response(status: .ok, body: .init(data: imageData))
        response.headers.add(name: "Content-Type", value: "image/jpeg")
        response.headers.add(name: "Cache-Control", value: "public, max-age=3600")
        response.headers.add(name: "X-Cache", value: "MISS")
        return response

      } catch {
        return Response(
          status: .internalServerError,
          body: .init(string: "Failed to load image: \(error.localizedDescription)"))
      }
    }
  }
}

enum ImageType: String, CaseIterable {
  case thumbnail = "thumbnail"
  case fullsize = "fullsize"
}
