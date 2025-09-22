# Photo Gallery App

A demonstration project showcasing clean architecture, performance optimization, and proper iOS development patterns through two different implementations: **UIKit + MVC** and **SwiftUI + MVVM**.

> **Inspiration**: This project is based on a system design question from [TikTok iOS technical interview](https://samwize.com/2020/11/21/my-technical-interview-with-tiktok-ios-singapore/#google_vignette) by @samwize, implemented as a learning exercise to demonstrate different architectural approaches.

## Project Overview

This project demonstrates best practices in iOS development by implementing the same photo gallery functionality using two different architectural approaches. The focus is on:

- **Clean Architecture**: Clear separation of concerns, proper dependency management
- **Performance Optimization**: Efficient memory management, smooth scrolling, optimized image loading
- **Code Quality**: Proper threading, memory safety, maintainable code structure
- **Modern iOS Patterns**: Latest iOS development practices and design patterns

## Features

- 📷 Photo library access with permission handling
- 🖼️ Grid-based photo gallery with infinite scroll
- 💾 Intelligent caching system for thumbnails and full images
- ❤️ Favorite photos functionality
- 🔍 Detailed photo viewing
- 🧠 Memory management with sliding window approach
- ⚡ Optimized performance with proper threading

## Architecture Implementations

### UIKit + MVC Implementation

#### **Pattern**: Model-View-Controller
- **Models**: `PhotoItem` - Represents individual photos with observer pattern
- **Views**: `PhotoCell`, `PhotoGalleryViewController`, `PhotoDetailsViewController`
- **Controllers**: ViewControllers handle user interaction and coordinate between models and views

#### **Key Design Choices**:

**Threading Strategy**:
- `DispatchQueue.main.async` placed at the UI update level (ViewControllers)
- `DispatchGroup` to manage concurrent fetch
- Services remain thread-agnostic for maximum flexibility
- Observer pattern with manual threading control

**Memory Management**:
- Manual `[weak self]` capture lists to prevent retain cycles
- Sliding window approach with `maxPhotosInMemory` limit
- `isLoading` flag to prevent overlapping requests


**Observer Pattern**:
```swift
protocol PhotoItemObserver: AnyObject {
  func photoItemDidUpdate(_ photoItem: PhotoItem, at index: Int)
}
```

### SwiftUI + MVVM Implementation

#### **Pattern**: Model-View-ViewModel
- **Models**: `PhotoCellViewState` - Observable objects for individual photos
- **Views**: `PhotoGalleryView`, `PhotoCellView`, `PhotoDetailsView`
- **ViewModels**: `PhotoGalleryViewModel`, `PhotoDetailsViewModel` - Business logic and state management

#### **Key Design Choices**:

**Reactive Programming**:
- Combine publishers for asynchronous operations
- Declarative UI updates through `@Published` properties
- Functional reactive chains with built-in backpressure

**State Management**:
- `@StateObject` and `@ObservableObject` for automatic UI updates
- Publisher chains handle complex async operations
- No manual threading required - Combine handles it


**Reactive Chain Example**:
```swift
loadMoreSubject
  .filter { [weak self] in self?.canLoadMore ?? false }
  .flatMap { Self.photosService.fetchPhotos(...) }
  .flatMap { Self.photosService.fetchThumbnails(...) }
  .sink { /* Update UI */ }
```

## Service Layer Architecture

Both implementations share identical service interfaces but differ in return types:

### Shared Services:
- **PhotosService**: Photo fetching and management
- **PhotoPermissionsService**: Permission handling
- **CacheService**: Image caching with hash-based keys
- **FavoritingService**: Favorite photos management using UserDefaults for persistence

## Comparison Table

| Aspect | UIKit + MVC | SwiftUI + MVVM |
|--------|-------------|----------------|
| **Architecture Pattern** | Model-View-Controller | Model-View-ViewModel |
| **UI Framework** | UIKit (Imperative) | SwiftUI (Declarative) |
| **Async Handling** | Completion Handlers | Combine Publishers |
| **State Management** | Manual delegation/Observer pattern | Reactive (@Published) |
| **Threading** | Manual `DispatchQueue` + `DispatchGroup` | Combine automatic |
| **Memory Safety** | Manual `[weak self]` | ARC + Publisher 
| **Performance** | Fine-grained control | Combine optimizations |
| **Overlap Prevention** | Manual `isLoading` flag | Combine built-in handling |
| **UI Updates** | Explicit calls | Automatic (@Published) |
| **Error Handling** | Traditional try/catch | Publisher error operators |

## Key Architectural Decisions

### 1. **Separation of Concerns**
- Services handle business logic only
- ViewModels/Controllers handle UI state
- Views handle presentation only

### 2. **Asynchronous / Multi-threading Strategies**
- **UIKit**: Uses GCD DispatchQueue and DispatchGroup for explicit thread management at UI boundaries
- **SwiftUI**: Leverages Combine publishers for reactive async operations with automatic thread handling

### 3. **Memory Management**
- Sliding window approach for large photo collections
- Hash-based caching for efficient lookup
- Proper cleanup and lifecycle management

### 4. **Performance Optimizations**

#### **Shared Optimizations (Both Implementations)**:
- **In-memory caching**: NSCache for thumbnails and full images
- **Persistent favorites**: UserDefaults for storing favorited photo IDs across app launches
- **Sliding window memory management**: Loads up to 100 photos, evicts old ones as new ones load
- **Reusable UI components**: UICollectionViewCell (UIKit) and LazyVGrid (SwiftUI) for efficient scrolling
- **Calculated thumbnail sizes**: Request exact dimensions needed to prevent over-fetching
- **Time-based throttling**: 500ms debouncing prevents excessive API calls
- **Async background loading**: Non-blocking thumbnail loading for smooth UI

#### **UIKit-Specific Optimizations**:
- **Manual overlap prevention**: `isLoading` flag prevents concurrent load requests
- **GCD threading control**: Explicit DispatchQueue and DispatchGroup management
- **Fine-grained memory control**: Manual `[weak self]` capture lists

#### **SwiftUI-Specific Optimizations**:
- **Combine request handling**: Built-in overlapping request management through `flatMap`
- **Reactive debouncing**: Publisher operators handle throttling automatically
- **Publisher lifecycle management**: Automatic cleanup when publishers complete or cancel

### 5. **Error Handling**
- Consistent error types across both implementations
- Graceful degradation: individual thumbnail failures show placeholders without affecting other concurrent fetches
- Resilient concurrent operations: one failed request doesn't break the entire loading process
- Assertion failures for impossible states to catch development bugs

## Code Quality Standards

This project demonstrates:
- ✅ Proper memory management
- ✅ Thread safety
- ✅ Clean architecture principles
- ✅ Performance optimization
- ✅ Consistent error handling
- ✅ Maintainable code structure
- ✅ Modern iOS development patterns

## Conclusion

Both implementations achieve the same functionality but showcase different approaches to iOS development. The UIKit version provides explicit control and traditional patterns, while the SwiftUI version leverages reactive programming for cleaner, more declarative code. The choice between them depends on team familiarity, project requirements, and architectural preferences.