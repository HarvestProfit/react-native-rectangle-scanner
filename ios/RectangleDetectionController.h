//
//  IPDFCameraViewController.h
//  InstaPDF
//
//  Created by Maximilian Mackh on 06/01/15.
//  Copyright (c) 2015 mackh ag. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CameraDeviceController.h"

typedef NS_ENUM(NSInteger, ScannerRectangleType)
{
    RCIPDFRectangeTypeGood,
    RCIPDFRectangeTypeBadAngle,
    RCIPDFRectangeTypeTooFar
};

@protocol RectangleDetectionDelegate <NSObject>

- (void) didDetectRectangle: (CIRectangleFeature*) rectangle withType: (ScannerRectangleType) type image: (CIImage *) image confidence: (NSInteger) confidence;

@end

@interface RectangleDetectionController : CameraDeviceController

- (void)setupCameraView;

- (void)start;
- (void)stop;

@property (nonatomic,assign,getter=isBorderDetectionEnabled) BOOL enableBorderDetection;

@property (weak, nonatomic) id<RectangleDetectionDelegate> delegate;

- (void)captureImageWithCompletionHander:(void(^)(UIImage *data, UIImage *initialData, CIRectangleFeature *rectangleFeature))completionHandler;

- (CIImage *)processOutput:(CIImage *)image;
@property (nonatomic, assign) NSInteger detectionRefreshRateInMS;

@end
