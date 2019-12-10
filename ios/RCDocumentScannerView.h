#import "RectangleDetectionController.h"
#import <React/RCTViewManager.h>

@interface RCDocumentScannerView : RectangleDetectionController <RectangleDetectionDelegate>

@property (nonatomic, copy) RCTBubblingEventBlock onPictureTaken;
@property (nonatomic, copy) RCTBubblingEventBlock onRectangleDetect;
@property (nonatomic, copy) RCTBubblingEventBlock onDeviceSetup;
@property (nonatomic, assign) BOOL captureOnDetect;
@property (nonatomic, assign) NSInteger detectionCountBeforeCapture;
@property (assign, nonatomic) NSInteger stableCounter;
@property (nonatomic, assign) float quality;
@property (nonatomic, assign) BOOL useBase64;
@property (nonatomic, assign) BOOL saveInAppDocument;

- (void) capture;
- (void) startCamera;
- (void) stopCamera;

@end
