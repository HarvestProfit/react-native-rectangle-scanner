//
//  RNRectangleScannerView.h
//
//  Created by Jake Humphrey on Jan 6, 2020.
//  Copyright (c) 2020 Jake Humphrey. All rights reserved.
//


#import "RectangleDetectionController.h"
#import <React/RCTViewManager.h>

@interface RNRectangleScannerView : RectangleDetectionController

@property (nonatomic, copy) RCTDirectEventBlock onDeviceSetup;
@property (nonatomic, copy) RCTDirectEventBlock onTorchChanged;
@property (nonatomic, copy) RCTDirectEventBlock onPictureTaken;
@property (nonatomic, copy) RCTDirectEventBlock onPictureProcessed;
@property (nonatomic, copy) RCTDirectEventBlock onErrorProcessingImage;
@property (nonatomic, copy) RCTDirectEventBlock onRectangleDetected;

@property (nonatomic, assign) float capturedQuality;

- (void) capture;
- (void) startCamera;
- (void) stopCamera;
- (void) cleanup;

@end
