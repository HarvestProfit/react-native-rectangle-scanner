//
//  RNRectangleScannerView.h
//
//  Created by Jake Humphrey on Jan 6, 2020.
//  Copyright (c) 2020 Jake Humphrey. All rights reserved.
//


#import "RectangleDetectionController.h"
#import <React/RCTViewManager.h>

@interface RNRectangleScannerView : RectangleDetectionController

@property (nonatomic, copy) RCTBubblingEventBlock onDeviceSetup;
@property (nonatomic, copy) RCTBubblingEventBlock onTorchChanged;
@property (nonatomic, copy) RCTBubblingEventBlock onPictureTaken;
@property (nonatomic, copy) RCTBubblingEventBlock onPictureProcessed;
@property (nonatomic, copy) RCTBubblingEventBlock onRectangleDetected;

@property (nonatomic, assign) float capturedQuality;
@property (nonatomic, assign) NSString *cacheFolderName;

- (void) capture;
- (void) startCamera;
- (void) stopCamera;
- (void) cleanup;

@end
