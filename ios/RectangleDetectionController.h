//
//  IPDFCameraViewController.h
//  InstaPDF
//
//  Created by Maximilian Mackh on 06/01/15.
//  Copyright (c) 2015 mackh ag. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CameraDeviceController.h"
#import <React/RCTViewManager.h>

typedef NS_ENUM(NSInteger, ScannerRectangleType)
{
    RCIPDFRectangeTypeGood,
    RCIPDFRectangeTypeBadAngle,
    RCIPDFRectangeTypeTooFar
};

@interface RectangleDetectionController : CameraDeviceController

- (void)setupCameraView;

- (void)start;
- (void)stop;
- (void)rectangleWasDetected:(NSDictionary *)detection;

@property (nonatomic,assign,getter=isBorderDetectionEnabled) BOOL enableBorderDetection;

- (void)captureImageWithCompletionHander:(void(^)(UIImage *data, UIImage *initialData, CIRectangleFeature *rectangleFeature))completionHandler;

- (CIImage *)processOutput:(CIImage *)image;
@property (nonatomic, assign) NSInteger detectionRefreshRateInMS;

@end
