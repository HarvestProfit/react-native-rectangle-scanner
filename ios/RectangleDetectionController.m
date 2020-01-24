//
//  RectangleDetectionController.m
//
//  Created by Jake Humphrey on Jan 6, 2020.
//  Copyright (c) 2020 Jake Humphrey. All rights reserved.
//

#import "RectangleDetectionController.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>

@interface RectangleDetectionController ()

@property (nonatomic, assign) float lastDetectionRate;

@end

/*!
 Takes the output from the camera device controller and attempts to detect rectangles from the output. On capture,
 it will also crop the image.
 */
@implementation RectangleDetectionController
{
  CGFloat _imageDedectionConfidence;
  NSTimer *_borderDetectTimeKeeper;
  BOOL _borderDetectFrame;
  CIRectangleFeature *_borderDetectLastRectangleFeature;
  CGRect _borderDetectLastRectangleBounds;
  dispatch_queue_t _rectangleDetectionQueue;
}

- (instancetype)init {
  self = [super init];
  _rectangleDetectionQueue = dispatch_queue_create("RectangleDetectionQueue",NULL);
  return self;
}

// MARK: Setters

/*!
 Turns on the image detection.  Once turned on, the next frame displayed on the previewlayer will get scanned for a
 rectangle then it will turn off the border detection.
 */
- (void)enableBorderDetectFrame
{
  _borderDetectFrame = YES;
}

// MARK: Camera

/*!
 Before setting up the camera, set the deduction confidence to 0
 */
- (void)setupCameraView
{
  _imageDedectionConfidence = 0.0;
  [super setupCameraView];
}

/*!
 Starts a capture sequence and starts a timer that will enable border detection for the set refresh rate.
 */
- (void)start
{
  [super start];

  float detectionRefreshRate = 20;
  CGFloat detectionRefreshRateInSec = detectionRefreshRate/100;
  _borderDetectTimeKeeper = [NSTimer scheduledTimerWithTimeInterval:detectionRefreshRateInSec target:self selector:@selector(enableBorderDetectFrame) userInfo:nil repeats:YES];
}

/*!
 Stops the capture session and stops the timer
 */
- (void)stop
{
  [super stop];

  [_borderDetectTimeKeeper invalidate];
}

/*!
 Runs each frame the image is being pushed to the preview layer
 */
-(CIImage *)processOutput:(CIImage *)image
{
  if (self.isBorderDetectionEnabled)
  {
    if (_borderDetectLastRectangleFeature) {
      _imageDedectionConfidence += .5;
    } else {
      _imageDedectionConfidence = 0.0f;
    }

    if (_borderDetectFrame) {
      [self detectRectangleFromImageLater:image];
      _borderDetectFrame = NO;
    }
  }
  return [super processOutput:image];
}

/*!
 Looks for a rectangle in the given image async
 */
- (void)detectRectangleFromImageLater:(CIImage *)image {
  dispatch_async(_rectangleDetectionQueue, ^{

    @autoreleasepool {
      @try {
        // need to convert the CI image to a CG image before use, otherwise there can be some unexpected behaviour on some devices
        CIContext *context = [CIContext contextWithOptions:nil];
        CGImageRef cgDetectionImage = [context createCGImage:image fromRect:image.extent];
        CIImage *detectionImage = [CIImage imageWithCGImage:cgDetectionImage];
        detectionImage = [detectionImage imageByApplyingOrientation:kCGImagePropertyOrientationLeft];

        self->_borderDetectLastRectangleFeature = [self biggestRectangleInRectangles:[[self highAccuracyRectangleDetector] featuresInImage:detectionImage] image:detectionImage];
        self->_borderDetectLastRectangleBounds = detectionImage.extent;

        if (self->_borderDetectLastRectangleFeature) {
          NSDictionary *rectangleCoordinates = [self computeRectangle:self->_borderDetectLastRectangleFeature forImage: detectionImage];

          [self rectangleWasDetected:@{
            @"detectedRectangle": rectangleCoordinates,
          }];
        } else {
          [self rectangleWasDetected:@{
            @"detectedRectangle": @FALSE,
          }];
        }

        CGImageRelease(cgDetectionImage);
      }
      @catch (NSException * e) {
        NSLog(@"Failed to parse image: %@", e);
      }
    }
  });
}

- (void)rectangleWasDetected:(NSDictionary *)detection {}

// MARK: Capture
/*!
 After an image is captured and cropped, this method is called
 */
-(void)onProcessedCapturedImage:(UIImage *)croppedImage initialImage: (UIImage *) initialImage lastRectangleFeature: (CIRectangleFeature *) lastRectangleFeature {
}

/*!
After an image is captured, this fuction is called and handles cropping the image
*/
-(void)handleCapturedImage:(CIImage *)capturedImage orientation: (UIImageOrientation) orientation{
  if (self.isBorderDetectionEnabled && isRectangleDetectionConfidenceHighEnough(self->_imageDedectionConfidence) &&
      self->_borderDetectLastRectangleFeature)
  {
    CIImage *croppedImage = [self correctPerspectiveForImage:capturedImage withFeatures:self->_borderDetectLastRectangleFeature fromBounds:self->_borderDetectLastRectangleBounds];


    // need to convert the CI image to a CG image before use, otherwise there can be some unexpected behaviour on some devices
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef croppedref = [context createCGImage:croppedImage fromRect:croppedImage.extent];
    UIImage *image = [UIImage imageWithCGImage:croppedref scale: 1.0 orientation:orientation];

    CGImageRef capturedref = [context createCGImage:capturedImage fromRect:capturedImage.extent];
    UIImage *initialImage = [UIImage imageWithCGImage:capturedref scale: 1.0 orientation:orientation];

    [self onProcessedCapturedImage:image initialImage: initialImage lastRectangleFeature: self->_borderDetectLastRectangleFeature];

    CGImageRelease(croppedref);
    CGImageRelease(capturedref);
  } else {
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef capturedref = [context createCGImage:capturedImage fromRect:capturedImage.extent];
    UIImage *initialImage = [UIImage imageWithCGImage:capturedref scale: 1.0 orientation:orientation];
    [self onProcessedCapturedImage:nil initialImage: initialImage lastRectangleFeature: nil];
    CGImageRelease(capturedref);
  }
}

/*!
 Crops the image for the given coordinates, correcting its perspective.
 */
- (CIImage *)correctPerspectiveForImage:(CIImage *)image withFeatures:(CIRectangleFeature *)rectangleFeature fromBounds:(CGRect)bounds
{

  float xScale = image.extent.size.width / bounds.size.width;
  float yScale = image.extent.size.height / bounds.size.height;

  NSMutableDictionary *rectangleCoordinates = [NSMutableDictionary new];
  CGPoint newLeft = CGPointMake(rectangleFeature.topLeft.x * xScale, rectangleFeature.topLeft.y * yScale);
  CGPoint newRight = CGPointMake(rectangleFeature.topRight.x * xScale, rectangleFeature.topRight.y * yScale);
  CGPoint newBottomLeft = CGPointMake(rectangleFeature.bottomLeft.x * xScale, rectangleFeature.bottomLeft.y * yScale);
  CGPoint newBottomRight = CGPointMake(rectangleFeature.bottomRight.x * xScale, rectangleFeature.bottomRight.y * yScale);


  rectangleCoordinates[@"inputTopLeft"] = [CIVector vectorWithCGPoint:newLeft];
  rectangleCoordinates[@"inputTopRight"] = [CIVector vectorWithCGPoint:newRight];
  rectangleCoordinates[@"inputBottomLeft"] = [CIVector vectorWithCGPoint:newBottomLeft];
  rectangleCoordinates[@"inputBottomRight"] = [CIVector vectorWithCGPoint:newBottomRight];

  return [image imageByApplyingFilter:@"CIPerspectiveCorrection" withInputParameters:rectangleCoordinates];
}

// MARK: Rectangle Detection

/*!
 Gets a rectangle detector that can be used to plug an image into and find the rectangles from
 */
- (CIDetector *)highAccuracyRectangleDetector
{
    static CIDetector *detector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        detector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh, CIDetectorReturnSubFeatures: @(YES) }];
    });
    return detector;
}

/*!
 Finds the best fitting rectangle from the list of rectangles found in the image
 */
- (CIRectangleFeature *)biggestRectangleInRectangles:(NSArray *)rectangles image:(CIImage *)image
{
  if (![rectangles count]) return nil;

  float halfPerimiterValue = 0;

  CIRectangleFeature *biggestRectangle = [rectangles firstObject];

  for (CIRectangleFeature *rect in rectangles) {
    CGPoint p1 = rect.topLeft;
    CGPoint p2 = rect.topRight;
    CGFloat width = hypotf(p1.x - p2.x, p1.y - p2.y);

    CGPoint p3 = rect.topLeft;
    CGPoint p4 = rect.bottomLeft;
    CGFloat height = hypotf(p3.x - p4.x, p3.y - p4.y);

    CGFloat currentHalfPerimiterValue = height + width;

    if (halfPerimiterValue < currentHalfPerimiterValue) {
      halfPerimiterValue = currentHalfPerimiterValue;
      biggestRectangle = rect;
    }
  }

  return biggestRectangle;
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
 Checks if the confidence of the current rectangle is above a threshold. The higher, the more likely the rectangle is the desired object to be scanned.
 */
BOOL isRectangleDetectionConfidenceHighEnough(float confidence)
{
    return (confidence > 1.0);
}

@end
