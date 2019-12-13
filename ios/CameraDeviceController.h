//
//  IPDFCameraViewController.h
//  InstaPDF
//
//  Created by Maximilian Mackh on 06/01/15.
//  Copyright (c) 2015 mackh ag. All rights reserved.
//

#import <UIKit/UIKit.h>

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
@property (nonatomic,assign,getter=isFrontCam) BOOL useFrontCam;

- (void)focusAtPoint:(CGPoint)point completionHandler:(void(^)(void))completionHandler;

- (void)captureImageWithCompletionHander:(void(^)(CIImage* enhancedImage))completionHandler;
- (CIImage *)processOutput:(CIImage *)image;
- (UIView *)getPreviewLayerView;
- (void)deviceDidSetup:(NSDictionary*) config;
- (CGRect)getBounds;
- (CIImage *)detectionFilter:(CIImage *)image;

@property (nonatomic, assign) BOOL hasTakenPhoto;
@property (nonatomic, assign) BOOL forceStop;
@property (nonatomic, assign) BOOL _isStopped;
@property (nonatomic, assign) BOOL _isCapturing;
@property (nonatomic, assign) int filter;
@property (nonatomic,strong) EAGLContext *context;
@property (nonatomic, strong) CIContext *_coreImageContext;

@end
