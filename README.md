# Photo Gallery App

A demonstration project showcasing clean architecture, performance optimization, and proper iOS development patterns through two different implementations: **UIKit + MVC** and **SwiftUI + MVVM**.

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
- 🔍 Full-screen photo viewing
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
- Services remain thread-agnostic for maximum flexibility
- Observer pattern with manual threading control

**Memory Management**:
- Manual `[weak self]` capture lists to prevent retain cycles
- Sliding window approach with `maxPhotosInMemory` limit
- `isLoading` flag to prevent overlapping requests

**Performance Optimizations**:
- Calculated `thumbnailSize` based on screen dimensions
- Time-based throttling (500ms) for scroll events
- Centralized loading logic in `canLoadMore`

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

**Performance Optimizations**:
- Combine's `flatMap` naturally handles overlapping requests
- Built-in debouncing through publisher operators
- Automatic memory management through ARC and publisher lifecycle

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
- **FavoritingService**: Favorite photos management

### Implementation Differences:
- **UIKit**: Completion handler-based APIs
- **SwiftUI**: Combine Publisher-based APIs

## Performance Optimizations

### Memory Management
- **Sliding Window**: Keep only 100 photos in memory, remove older photos
- **Intelligent Caching**: Separate caches for thumbnails and full images
- **Proper Cleanup**: Automatic cache management with count limits

### Threading Optimization
- **UIKit**: Manual thread management at UI boundaries
- **SwiftUI**: Combine handles threading automatically
- **Services**: Thread-agnostic design for maximum flexibility

### Loading Optimization
- **Debouncing**: 500ms throttling to prevent excessive requests
- **Request Deduplication**: Prevent overlapping load operations
- **Calculated Sizes**: Request exact thumbnail sizes needed

## Comparison Table

| Aspect | UIKit + MVC | SwiftUI + MVVM |
|--------|-------------|----------------|
| **Architecture Pattern** | Model-View-Controller | Model-View-ViewModel |
| **UI Framework** | UIKit (Imperative) | SwiftUI (Declarative) |
| **Async Handling** | Completion Handlers | Combine Publishers |
| **State Management** | Manual delegation/KVO | Reactive (@Published) |
| **Threading** | Manual `DispatchQueue` | Combine automatic |
| **Memory Safety** | Manual `[weak self]` | ARC + Publisher lifecycle |
| **Code Verbosity** | Higher (manual setup) | Lower (declarative) |
| **Learning Curve** | Moderate (familiar) | Steeper (reactive concepts) |
| **Debugging** | Traditional breakpoints | Publisher chain debugging |
| **Performance** | Fine-grained control | Combine optimizations |
| **Overlap Prevention** | Manual `isLoading` flag | Combine built-in handling |
| **UI Updates** | Explicit calls | Automatic (@Published) |
| **Error Handling** | Traditional try/catch | Publisher error operators |

## Key Architectural Decisions

### 1. **Separation of Concerns**
- Services handle business logic only
- ViewModels/Controllers handle UI state
- Views handle presentation only

### 2. **Threading Strategy**
- **UIKit**: Explicit control at UI boundaries
- **SwiftUI**: Trust Combine's threading model

### 3. **Memory Management**
- Sliding window approach for large photo collections
- Hash-based caching for efficient lookup
- Proper cleanup and lifecycle management

### 4. **Performance First**
- Calculated thumbnail sizes prevent over-fetching
- Debouncing prevents excessive API calls
- Efficient observer patterns minimize unnecessary updates

### 5. **Error Handling**
- Consistent error types across both implementations
- Graceful degradation with fallback UI states
- Assertion failures for impossible states

## Getting Started

1. Clone the repository
2. Open either implementation in Xcode
3. Grant photo library permissions when prompted
4. Browse your photo library with smooth performance!

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