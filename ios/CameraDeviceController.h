//
//  CameraDeviceController.h
//
//  Created by Jake Humphrey on Jan 6, 2020.
//  Copyright (c) 2020 Jake Humphrey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface CameraDeviceController : UIView

- (void)setupCameraView;

- (void)start;
- (void)stop;

@property (nonatomic,assign,getter=isTorchEnabled) BOOL enableTorch;

- (void)focusAtPoint:(CGPoint)point completionHandler:(void(^)(void))completionHandler;

- (void)captureImageLater;
- (CIImage *)processOutput:(CIImage *)image;
- (UIView *)getPreviewLayerView;
- (CGRect)getBounds;

- (void)deviceWasSetup:(NSDictionary *)config;
- (void)torchWasChanged:(BOOL)enableTorch;
- (void)handleCapturedImage:(CIImage *)capturedImage;

@property (nonatomic, assign) BOOL hasTakenPhoto;
@property (nonatomic, assign) BOOL forceStop;
@property (nonatomic, assign) BOOL _isStopped;
@property (nonatomic, assign) BOOL _cameraIsSetup;
@property (nonatomic, assign) BOOL _isCapturing;
@property (nonatomic, assign) int filterId;
@property (nonatomic,strong) EAGLContext *context;
@property (nonatomic, strong) CIContext *_coreImageContext;

@end
