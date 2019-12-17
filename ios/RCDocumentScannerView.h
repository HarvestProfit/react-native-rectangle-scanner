#import "RectangleDetectionController.h"
#import <React/RCTViewManager.h>

@interface RCDocumentScannerView : RectangleDetectionController

@property (nonatomic, copy) RCTBubblingEventBlock onDeviceSetup;
@property (nonatomic, copy) RCTBubblingEventBlock onTorchChanged;
@property (nonatomic, copy) RCTBubblingEventBlock onPictureTaken;
@property (nonatomic, copy) RCTBubblingEventBlock onPictureProcessed;
@property (nonatomic, copy) RCTBubblingEventBlock onRectangleDetected;

@property (nonatomic, assign) float capturedQuality;

- (void) capture;
- (void) startCamera;
- (void) stopCamera;
- (void) cleanup;

@end
