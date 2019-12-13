#import "RCDocumentScannerView.h"

@implementation RCDocumentScannerView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setEnableBorderDetection:YES];
        [self setDelegate: self];
    }

    return self;
} 

/*!
 Called when a rectangle is detected
 */
- (void) didDetectRectangle:(CIRectangleFeature *)rectangle withType:(ScannerRectangleType)type image:(CIImage *)image confidence: (NSInteger) confidence {
  NSLog(@"Did Detect");
  switch (type) {
    case RCIPDFRectangeTypeGood:
      self.stableCounter ++;
      break;
    default:
      self.stableCounter = 0;
      break;
  }
  if (self.onRectangleDetect) {
    NSLog(@"prepare coords Detect");
    NSDictionary *rectangleCoordinates = [self computeRectangle:rectangle forImage: image];
    
    NSLog(@"emit Detect");
    self.onRectangleDetect(@{
      @"stableCounter": @(self.stableCounter),
      @"lastDetectionType": @(type),
      @"rectangleCoordinates": rectangleCoordinates,
      @"confidence": @(confidence)
    });
  }

  NSLog(@"check Detect");
  if (self.captureOnDetect && self.hasTakenPhoto && self.stableCounter > self.detectionCountBeforeCapture){
    NSLog(@"Detect capture");
    [self capture];
  }
}

/*!
 Used to start the camera if it is stopped
 */
- (void) startCamera {
  if ([self _isStopped]) [self start];
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
}

/*!
 Called after the camera and session are set up. This lets you check if a camera is found and permission is granted to use it.
 */
- (void)deviceDidSetup:(NSDictionary*) config
{
  if (self.onDeviceSetup) {
    self.onDeviceSetup(config);
  }
}

/*!
 Maps the coordinates to the correct orientation.  This maybe can be cleaned up and removed if the orientation is set on the input image.
 */
- (NSDictionary *) computeRectangle: (CIRectangleFeature *) rectangle forImage: (CIImage *) image {
  CGRect imageBounds = image.extent;
  if (!rectangle) return nil;
  return @{
    @"bottomLeft": @{
        @"y": @(rectangle.topLeft.x),
        @"x": @(rectangle.topLeft.y)
    },
    @"bottomRight": @{
        @"y": @(rectangle.topRight.x),
        @"x": @(rectangle.topRight.y)
    },
    @"topLeft": @{
        @"y": @(rectangle.bottomLeft.x),
        @"x": @(rectangle.bottomLeft.y)
    },
    @"topRight": @{
        @"y": @(rectangle.bottomRight.x),
        @"x": @(rectangle.bottomRight.y)
    },
    @"dimensions": @{@"height": @(imageBounds.size.width), @"width": @(imageBounds.size.height)}
  };
}

/*!
 Captures the current frame and sends the processed image(s) to the on picture taken callback.
 
 @note Sometimes this hangs.  Needs to be rewritten to be processed in a different thread with a timeout so the UI can continue running.
 */
- (void) capture {
  self.hasTakenPhoto = TRUE;
  self.stableCounter = -5;
    [self captureImageWithCompletionHander:^(UIImage *croppedImage, UIImage *initialImage, CIRectangleFeature *rectangleFeature) {
      NSLog(@"Complete handler");
      [self setEnableTorch: NO];
      NSLog(@"Torch off");
      if (self.onPictureTaken) {
        NSLog(@"on picture taken");
            NSData *croppedImageData = UIImageJPEGRepresentation(croppedImage, self.quality);

        NSLog(@"cropped image jpeg");
            if (initialImage.imageOrientation != UIImageOrientationUp) {
                UIGraphicsBeginImageContextWithOptions(initialImage.size, false, initialImage.scale);
                [initialImage drawInRect:CGRectMake(0, 0, initialImage.size.width
                                                    , initialImage.size.height)];
                initialImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }
        NSLog(@"initial image orientation");
            NSData *initialImageData = UIImageJPEGRepresentation(initialImage, self.quality);
        NSLog(@"initial image orientation");

            if (self.useBase64) {
              NSLog(@"base 64");
              self.onPictureTaken(@{
                                    @"croppedImage": [croppedImageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength],
                                    @"initialImage": [initialImageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]
              });
            }
            else {
              NSLog(@"store");
                NSString *dir = NSTemporaryDirectory();
                if (self.saveInAppDocument) {
                  NSLog(@"save");
                    dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
                  NSLog(@"save done");
                }
               NSString *croppedFilePath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"cropped_img_%i.jpeg",(int)[NSDate date].timeIntervalSince1970]];
              NSLog(@"crop file path");
               NSString *initialFilePath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"initial_img_%i.jpeg",(int)[NSDate date].timeIntervalSince1970]];

              NSLog(@"init file path");
              [croppedImageData writeToFile:croppedFilePath atomically:YES];
              NSLog(@"write crop");
              [initialImageData writeToFile:initialFilePath atomically:YES];
              NSLog(@"write init");

               self.onPictureTaken(@{
                                     @"croppedImage": croppedFilePath,
                                     @"initialImage": initialFilePath
                                     
               });
              NSLog(@"pic done");
            }
        }
      self.hasTakenPhoto = FALSE;
    }];
}


@end
