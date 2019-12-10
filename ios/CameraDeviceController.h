//
//  IPDFCameraViewController.h
//  InstaPDF
//
//  Created by Maximilian Mackh on 06/01/15.
//  Copyright (c) 2015 mackh ag. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,RCIPDFCameraViewType)
{
    RCIPDFCameraViewTypeBlackAndWhite,
    RCIPDFCameraViewTypeNormal
};

@interface CameraDeviceController : UIView

- (void)setupCameraView;

- (void)start;
- (void)stop;

@property (nonatomic,assign,getter=isTorchEnabled) BOOL enableTorch;
@property (nonatomic,assign,getter=isFrontCam) BOOL useFrontCam;

@property (nonatomic,assign) RCIPDFCameraViewType cameraViewType;

- (void)focusAtPoint:(CGPoint)point completionHandler:(void(^)(void))completionHandler;

- (void)captureImageWithCompletionHander:(void(^)(CIImage* enhancedImage))completionHandler;
- (CIImage *)processOutput:(CIImage *)image;
- (UIView *)getPreviewLayerView;
- (BOOL)hasFlash;
- (void)flashEnabledHandler:(BOOL)deviceHasFlash;

@property (nonatomic, assign) float saturation;
@property (nonatomic, assign) BOOL hasTakenPhoto;
@property (nonatomic, assign) float contrast;
@property (nonatomic, assign) float brightness;
@property (nonatomic, assign) BOOL forceStop;
@property (nonatomic, assign) BOOL _isStopped;
@property (nonatomic, assign) BOOL _isCapturing;
@property (nonatomic,strong) EAGLContext *context;
@property (nonatomic, strong) CIContext *_coreImageContext;

@end
