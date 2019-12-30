#import "RCDocumentScannerView.h"

@implementation RCDocumentScannerView

- (instancetype)init {
  self = [super init];
  if (self) {
    [self setEnableBorderDetection:YES];
    self._isStopped = TRUE;
    self._cameraIsSetup = FALSE;
    self.capturedQuality = 0.5;
  }

  return self;
}

/*!
 Used to start the camera if it is stopped
 */
- (void) startCamera {
  if ([self _isStopped]) {
    if (![self _cameraIsSetup]) {
      [self setupCameraView];
    }
    [self start];
  }
}

/*!
 Used to stop the camera if it is running
 */
- (void) stopCamera {
  if (![self _isStopped]) [self stop];
}

/*!
 Turns off the torch and stops the camera.
 */
- (void) cleanup {
  [self setEnableTorch: NO];
  [self stopCamera];
  self._cameraIsSetup = NO;
}


/*!
 Called after the camera and session are set up. This lets you check if a camera is found and permission is granted to use it.
 */
- (void)deviceWasSetup:(NSDictionary *)config {
  [super deviceWasSetup:config];
  if (self.onDeviceSetup) {
    self.onDeviceSetup(config);
  }
}


/*!
 Called after the torch state is changed
 */
- (void)torchWasChanged:(BOOL)torchEnabled {
  if (self.onTorchChanged) {
    self.onTorchChanged(@{@"enabled": torchEnabled ? @TRUE : @FALSE});
  }
}

/*!
 Called after the camera and session are set up. This lets you check if a camera is found and permission is granted to use it.
 */
- (void)rectangleWasDetected:(NSDictionary *)detection {
  [super rectangleWasDetected:detection];
  if (self.onRectangleDetected) {
    self.onRectangleDetected(detection);
  }
}

/*!
After capture, the image is stored and sent to the event handler
*/
-(void)onProcessedCapturedImage:(UIImage *)croppedImage initialImage: (UIImage *) initialImage lastRectangleFeature: (CIRectangleFeature *) lastRectangleFeature {
  NSString *dir = NSTemporaryDirectory();

  NSString *croppedFilePath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"cropped_img_%i.jpeg",(int)[NSDate date].timeIntervalSince1970]];
  NSString *initialFilePath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"initial_img_%i.jpeg",(int)[NSDate date].timeIntervalSince1970]];

  if (self.onPictureTaken) {
    self.onPictureTaken(@{
      @"croppedImage": croppedFilePath,
      @"initialImage": initialFilePath
    });
  }

  float quality = self.capturedQuality || 0.5;
  @autoreleasepool {
    NSData *croppedImageData = UIImageJPEGRepresentation(croppedImage, quality);
    NSData *initialImageData = UIImageJPEGRepresentation(initialImage, quality);
    [croppedImageData writeToFile:croppedFilePath atomically:YES];
    [initialImageData writeToFile:initialFilePath atomically:YES];

    if (self.onPictureProcessed) {
      self.onPictureProcessed(@{
        @"croppedImage": croppedFilePath,
        @"initialImage": initialFilePath
      });
    }
  }
}

/*!
 Captures the current frame and sends the processed image(s) to the on picture taken callback.
 */
- (void) capture {
  [self captureImageLater];
}


@end
