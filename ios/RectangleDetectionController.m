//
//  IPDFCameraViewController.m
//  InstaPDF
//
//  Created by Maximilian Mackh on 06/01/15.
//  Copyright (c) 2015 mackh ag. All rights reserved.
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

@implementation RectangleDetectionController
{
    CGFloat _imageDedectionConfidence;
    NSTimer *_borderDetectTimeKeeper;
    BOOL _borderDetectFrame;
    CIRectangleFeature *_borderDetectLastRectangleFeature;
  CGRect _borderDetectLastRectangleBounds;
    NSInteger _detectionRefreshRateInMS;
}

// MARK: Setters

/*!
 Determines how often the enableBorderDetectFrame setter is called from the timer
 */
- (void)setDetectionRefreshRateInMS:(NSInteger)detectionRefreshRateInMS
{
    _detectionRefreshRateInMS = detectionRefreshRateInMS;
}

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
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    @autoreleasepool {
      CIImage * detectionImage = [image imageByApplyingOrientation:kCGImagePropertyOrientationLeft];
      
      self->_borderDetectLastRectangleFeature = [self biggestRectangleInRectangles:[[self highAccuracyRectangleDetector] featuresInImage:detectionImage] image:detectionImage];
      self->_borderDetectLastRectangleBounds = detectionImage.extent;
      
      if (self->_borderDetectLastRectangleFeature) {
        NSDictionary *rectangleCoordinates = [self computeRectangle:self->_borderDetectLastRectangleFeature forImage: detectionImage];
        
        [self rectangleWasDetected:@{
          @"lastDetectionType": @(RCIPDFRectangeTypeTooFar),
          @"detectedRectangle": rectangleCoordinates,
          @"confidence": @(self->_imageDedectionConfidence)
        }];
      } else {
        [self rectangleWasDetected:@{
          @"lastDetectionType": @(RCIPDFRectangeTypeTooFar),
          @"detectedRectangle": @FALSE,
          @"confidence": @(self->_imageDedectionConfidence)
        }];
      }
    }
  });
}

- (void)rectangleWasDetected:(NSDictionary *)detection {}

// MARK: Capture
/*!
 Captures the current frame from the camera, if it has detected a border, then it will crop the image and send the cropped image and original image to the
 completion handler.
 */
- (void)captureImageWithCompletionHander:(void(^)(UIImage *data, UIImage *initialData, CIRectangleFeature *rectangleFeature))completionHandler
{
  [super captureImageWithCompletionHander:^(CIImage* enhancedImage){
    if (self.isBorderDetectionEnabled && isRectangleDetectionConfidenceHighEnough(self->_imageDedectionConfidence))
    {
      if (self->_borderDetectLastRectangleFeature)
        {
          CIImage *croppedImage = [self correctPerspectiveForImage:enhancedImage withFeatures:self->_borderDetectLastRectangleFeature fromBounds:self->_borderDetectLastRectangleBounds];
          UIImage *image = [UIImage imageWithCIImage:croppedImage scale: 1.0 orientation:UIImageOrientationRight];
          UIImage *initialImage = [UIImage imageWithCIImage:enhancedImage scale: 1.0 orientation:UIImageOrientationRight];
          completionHandler(image, initialImage, self->_borderDetectLastRectangleFeature);
        }
    } else {
        UIImage *initialImage = [UIImage imageWithCIImage:enhancedImage scale: 1.0 orientation:UIImageOrientationRight];
        completionHandler(initialImage, initialImage, nil);
    }
  }];
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

/*!
 Gets the orientation that the image should be set to
 */
- (int)getOrientationForImage
{
  switch ([UIApplication sharedApplication].statusBarOrientation) {
  case UIDeviceOrientationPortrait:
      return UIImageOrientationRight;
  case UIDeviceOrientationPortraitUpsideDown:
      return UIImageOrientationLeft;
  case UIDeviceOrientationLandscapeLeft:
      return UIImageOrientationUp;
  case UIDeviceOrientationLandscapeRight:
      return UIImageOrientationDown;
  default:
      return UIImageOrientationRight;
  }
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
 Determines the potential quality of the contents of a rectangle
 */
- (ScannerRectangleType) typeForRectangle: (CIRectangleFeature*) rectangle {
  UIView *previewLayerView = [super getPreviewLayerView];
  if (fabs(rectangle.topRight.y - rectangle.topLeft.y) > 100 ||
      fabs(rectangle.topRight.x - rectangle.bottomRight.x) > 100 ||
      fabs(rectangle.topLeft.x - rectangle.bottomLeft.x) > 100 ||
      fabs(rectangle.bottomLeft.y - rectangle.bottomRight.y) > 100) {
    return RCIPDFRectangeTypeBadAngle;
  } else if ((previewLayerView.frame.origin.y + previewLayerView.frame.size.height) - rectangle.topLeft.y > 150 ||
             (previewLayerView.frame.origin.y + previewLayerView.frame.size.height) - rectangle.topRight.y > 150 ||
             previewLayerView.frame.origin.y - rectangle.bottomLeft.y > 150 ||
             previewLayerView.frame.origin.y - rectangle.bottomRight.y > 150) {
    return RCIPDFRectangeTypeTooFar;
  }
  return RCIPDFRectangeTypeGood;
}

/*!
 Checks if the confidence of the current rectangle is above a threshold. The higher, the more likely the rectangle is the desired object to be scanned.
 */
BOOL isRectangleDetectionConfidenceHighEnough(float confidence)
{
    return (confidence > 1.0);
}

@end
