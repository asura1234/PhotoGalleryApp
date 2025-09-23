# React Native Architecture Design Document

## Overview

This document outlines the architectural design for adding a React Native implementation to the Photo Gallery App project. The design leverages a hybrid approach combining React Native's Native Modules for metadata and a local HTTP server for efficient image data transfer.

## Architecture Principles

### **Hybrid Communication Strategy**
- **Native Modules**: Handle permissions, metadata, and photo information
- **Local HTTP Server**: Serve actual image data (thumbnails and full images)
- **Platform Separation**: Favoriting logic resides in React Native, not native code

### **Why Not Reuse Existing Services?**
Rather than adapting existing UIKit services, we implement fresh services optimized for React Native's needs:
- Clean separation of concerns
- No complex bridge serialization
- Platform-appropriate optimizations
- Easier debugging and maintenance

## Communication Pathways

### **Native Modules (Standard RN Bridge)**
Used for:
- Permission checking and requesting
- Photo metadata retrieval
- Lightweight JSON responses
- Standard React Native → Swift communication

### **Local HTTP Server**
Used for:
- Image data transfer (thumbnails and full images)
- Efficient binary data handling
- Built-in caching capabilities
- No App Transport Security issues (localhost exempt)

## Service Specifications

### **PhotoPermissionsService (Native Module)**

#### **Function Signature:**
```swift
func checkOrRequestPermissionWhenNeeded() -> Bool
```

#### **Implementation Logic:**
```swift
// Map iOS permission status to simple boolean
switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
case .authorized, .limited:
    return true  // User has granted permission
case .denied, .restricted:
    return false // User denied or restricted
case .notDetermined:
    // Request permission and return result
    return requestAndReturnBoolean()
}
```

#### **Response:**
- **Type**: Boolean
- **True**: Authorized or Limited access
- **False**: Denied, Restricted, or request failed

### **PhotosService (Native Module)**

#### **Function Signature:**
```swift
func getPhotos(startIndex: Int, batchSize: Int) -> [PhotoItem]
```

#### **Response Schema:**
```json
{
  "photos": [
    {
      "assetId": "12345-ABCD-6789-EFGH",
      "thumbnail_url": "http://localhost:8080/image?type=thumbnail&id=12345-ABCD-6789-EFGH&width=150&height=150",
      "image_url": "http://localhost:8080/image?type=fullsize&id=12345-ABCD-6789-EFGH",
      "metadata": {
        "created_date": "2024-01-15T10:30:00Z",
        "width": "4032",
        "height": "3024",
        "file_size": "2.5MB",
        "location": "37.7749,-122.4194"
      }
    }
  ],
  "total_count": 1500,
  "has_more": true
}
```

#### **Key Features:**
- **Pre-built URLs**: Ready-to-use localhost URLs for React Native `<Image>` components
- **Rich metadata**: All photo information needed for UI rendering
- **Pagination support**: Consistent with existing implementations

### **Local HTTP Image Server**

#### **Endpoint:**
```
GET /image?type={thumbnail|fullsize}&id={assetId}&width={optional}&height={optional}
```

#### **Query Parameters:**
- **type**: `thumbnail` or `fullsize`
- **id**: Asset identifier from PhotosService response
- **width**: Desired thumbnail width (optional, defaults to 200)
- **height**: Desired thumbnail height (optional, defaults to 200)

#### **Example Requests:**
```
GET /image?type=thumbnail&id=12345-ABCD&width=150&height=150
GET /image?type=fullsize&id=12345-ABCD
```

#### **Response:**
- **Content-Type**: `image/jpeg` or `image/heic`
- **Body**: Binary image data
- **Caching**: Server-side caching based on assetId + dimensions

## React Native Implementation

### **FavoritingService (React Native)**
- **Storage**: AsyncStorage or MMKV for persistence
- **State Management**: Redux, Zustand, or React Context
- **No Native Dependency**: Completely handled in TypeScript

### **Photo Gallery Component**
```tsx
import { Image } from 'react-native';

// Use URLs directly from PhotosService response
<Image
  source={{ uri: photo.thumbnail_url }}
  style={{ width: 150, height: 150 }}
/>
```

### **Permission Handling**
```tsx
const hasPermission = await PhotoPermissionsService.checkOrRequestPermissionWhenNeeded();
if (hasPermission) {
  const photos = await PhotosService.getPhotos(startIndex, batchSize);
  // Render photo grid
}
```

## Technical Benefits

### **Performance Advantages**
- **Efficient Image Transfer**: HTTP streaming for large images
- **No Bridge Serialization**: Images bypass React Native bridge entirely
- **Built-in Caching**: HTTP server handles image caching automatically
- **Parallel Loading**: Multiple concurrent image requests

### **Development Benefits**
- **Familiar Patterns**: Standard REST API instead of complex bridge logic
- **Easy Debugging**: HTTP traffic inspection with network tools
- **Platform Independence**: Each service optimized for its platform
- **Flexible Scaling**: Can add new endpoints without bridge changes

### **App Transport Security (ATS)**
- **No HTTPS Required**: Localhost connections exempt from ATS
- **No Configuration**: No Info.plist modifications needed
- **Secure by Default**: Local-only communication

## Implementation Strategy

### **Phase 1: Core Services**
1. Implement PhotoPermissionsService Native Module
2. Implement PhotosService Native Module
3. Create local HTTP image server
4. Test with simple photo grid

### **Phase 2: Feature Parity**
1. Implement FavoritingService in React Native
2. Add infinite scroll functionality
3. Implement photo detail view
4. Add memory management (sliding window)

### **Phase 3: Optimization**
1. Optimize HTTP server caching
2. Add image preloading strategies
3. Implement performance monitoring
4. Fine-tune memory usage

## Architectural Comparison

| Aspect | UIKit + MVC | SwiftUI + MVVM | React Native + Hybrid |
|--------|-------------|----------------|----------------------|
| **Image Loading** | NSCache | NSCache | HTTP Server Cache |
| **State Management** | Observer Pattern | @Published | Redux/Context |
| **Threading** | GCD + DispatchGroup | Combine | Native Modules + HTTP |
| **Memory Management** | Manual sliding window | Combine lifecycle | RN + Server-side |
| **Favoriting** | UserDefaults | UserDefaults | AsyncStorage |
| **Performance** | Native optimal | Native optimal | Near-native |

## Future Considerations

### **Potential Enhancements**
- **WebSocket Integration**: Real-time photo updates
- **Progressive Loading**: Blur-to-sharp image transitions
- **Background Sync**: Photo metadata caching
- **Analytics Integration**: Usage tracking and performance metrics

### **Cross-Platform Opportunities**
- **Shared Business Logic**: FavoritingService could be shared with Flutter
- **API Standardization**: HTTP endpoints could serve multiple platforms
- **Configuration Management**: Centralized app settings

## Conclusion

This hybrid architecture provides the best of both worlds: React Native's rapid development capabilities combined with native iOS performance for image handling. The separation between metadata (Native Modules) and binary data (HTTP server) creates a clean, scalable architecture that can easily accommodate future feature additions.