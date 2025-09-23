#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(PhotoPermissionsService, NSObject)

RCT_EXTERN_METHOD(checkOrRequestPermissionWhenNeeded:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

@end