//
//  RectangleDetectionController.h
//
//  Created by Jake Humphrey on Jan 6, 2020.
//  Copyright (c) 2020 Jake Humphrey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CameraDeviceController.h"
#import <React/RCTViewManager.h>

@interface RectangleDetectionController : CameraDeviceController

- (void)setupCameraView;

- (void)start;
- (void)stop;
- (void)rectangleWasDetected:(NSDictionary *)detection;
-(void)onProcessedCapturedImage:(UIImage *)croppedImage initialImage: (UIImage *) initialImage lastRectangleFeature: (CIRectangleFeature *) lastRectangleFeature;
- (void)handleCapturedImage:(CIImage *)capturedImage orientation:(UIImageOrientation)orientation;

@property (nonatomic,assign,getter=isBorderDetectionEnabled) BOOL enableBorderDetection;

- (CIImage *)processOutput:(CIImage *)image;
@property (nonatomic, assign) NSInteger detectionRefreshRateInMS;

@end
