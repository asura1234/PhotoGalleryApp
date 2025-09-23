#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(PhotosServiceNativeModule, NSObject)

RCT_EXTERN_METHOD(getPhotos:(NSNumber *)startIndex
                  batchSize:(NSNumber *)batchSize
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

@end