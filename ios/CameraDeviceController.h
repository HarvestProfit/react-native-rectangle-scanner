//
//  IPDFCameraViewController.h
//  InstaPDF
//
//  Created by Maximilian Mackh on 06/01/15.
//  Copyright (c) 2015 mackh ag. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <React/RCTViewManager.h>

typedef NS_ENUM(NSInteger, CameraFilterTypes)
{
    CameraFilterSepiaType,
    CameraFilterBlackAndWhiteType
};

@interface CameraDeviceController : UIView

- (void)setupCameraView;

- (void)start;
- (void)stop;

@property (nonatomic,assign,getter=isTorchEnabled) BOOL enableTorch;

- (void)focusAtPoint:(CGPoint)point completionHandler:(void(^)(void))completionHandler;

- (void)captureImageWithCompletionHander:(void(^)(CIImage* enhancedImage, int orientation))completionHandler;
- (CIImage *)processOutput:(CIImage *)image;
- (UIView *)getPreviewLayerView;
- (CGRect)getBounds;
- (CIImage *)detectionFilter:(CIImage *)image;

- (void)deviceWasSetup:(NSDictionary *)config;
- (void)torchWasChanged:(BOOL)enableTorch;

@property (nonatomic, assign) BOOL hasTakenPhoto;
@property (nonatomic, assign) BOOL forceStop;
@property (nonatomic, assign) BOOL _isStopped;
@property (nonatomic, assign) BOOL _cameraIsSetup;
@property (nonatomic, assign) BOOL _isCapturing;
@property (nonatomic, assign) int filterId;
@property (nonatomic,strong) EAGLContext *context;
@property (nonatomic, strong) CIContext *_coreImageContext;

@end
