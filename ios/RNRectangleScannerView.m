//
//  RNRectangleScannerView.m
//
//  Created by Jake Humphrey on Jan 6, 2020.
//  Copyright (c) 2020 Jake Humphrey. All rights reserved.
//

#import "RNRectangleScannerView.h"

/*!
 Wraps up the camera and rectangle detection code into a simple interface.  Allows you to call start, stop, cleanup, and capture. Also is responsible for deterining how to cache the output images.
 */
@implementation RNRectangleScannerView

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

- (void)onErrorOfImageProcessor:(NSDictionary*) errorBody {
  if (self.onErrorProcessingImage) {
    self.onErrorProcessingImage(errorBody);
  }
}

/*!
After capture, the image is stored and sent to the event handler
*/
-(void)onProcessedCapturedImage:(UIImage *)croppedImage initialImage: (UIImage *) initialImage lastRectangleFeature: (CIRectangleFeature *) lastRectangleFeature {
  NSString *dir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
  NSString *storageFolder = @"RNRectangleScanner";

  dir = [dir stringByAppendingPathComponent:storageFolder];

  NSFileManager *fileManager= [NSFileManager defaultManager];
  NSError *error = nil;
  if(![fileManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&error]) {
    // An error has occurred, do something to handle it
    NSLog(@"Failed to create directory \"%@\". Error: %@", dir, error);
    [self onErrorOfImageProcessor:@{@"message": @"Failed to create the cache directory"}];
    return;
  }

  NSString *croppedFilePath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"C%i.jpeg",(int)[NSDate date].timeIntervalSince1970]];
  NSString *initialFilePath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"O%i.jpeg",(int)[NSDate date].timeIntervalSince1970]];
  bool hasCroppedImage = (croppedImage != nil);
  if (!hasCroppedImage) {
    croppedFilePath = initialFilePath;
  }


  if (self.onPictureTaken) {
    self.onPictureTaken(@{
      @"croppedImage": croppedFilePath,
      @"initialImage": initialFilePath
    });
  }

  float quality = 0.5;
  if (self.capturedQuality) {
    quality = self.capturedQuality;
  }
  @autoreleasepool {
    if (hasCroppedImage) {
      NSData *croppedImageData = UIImageJPEGRepresentation(croppedImage, quality);
      if (![croppedImageData writeToFile:croppedFilePath atomically:YES]) {
        NSMutableDictionary *errorBody = [[NSMutableDictionary alloc] init];
        [errorBody setValue:@"Failed to write cropped image to cache" forKey:@"message"];
        [errorBody setValue:croppedFilePath forKey:@"filePath"];
        [self onErrorOfImageProcessor:errorBody];
        return;
      }
    }

    NSData *initialImageData = UIImageJPEGRepresentation(initialImage, quality);
    if (![initialImageData writeToFile:initialFilePath atomically:YES]) {
      NSMutableDictionary *errorBody = [[NSMutableDictionary alloc] init];
      [errorBody setValue:@"Failed to write original image to cache" forKey:@"message"];
      [errorBody setValue:initialFilePath forKey:@"filePath"];
      [self onErrorOfImageProcessor:errorBody];
      return;
    }

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
