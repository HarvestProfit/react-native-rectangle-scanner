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
    NSInteger _detectionRefreshRateInMS;
}

-(CIImage *)processOutput:(CIImage *)image
{
  image = [super processOutput:image];
  if (self.isBorderDetectionEnabled)
  {
    if (_borderDetectFrame)
    {
      _borderDetectLastRectangleFeature = [self biggestRectangleInRectangles:[[self highAccuracyRectangleDetector] featuresInImage:image]];
      _borderDetectFrame = NO;
    }

    if (_borderDetectLastRectangleFeature)
    {
      _imageDedectionConfidence += .5;

      image = [self drawHighlightOverlayForPoints:image topLeft:_borderDetectLastRectangleFeature.topLeft topRight:_borderDetectLastRectangleFeature.topRight bottomLeft:_borderDetectLastRectangleFeature.bottomLeft bottomRight:_borderDetectLastRectangleFeature.bottomRight];
    }
    else
    {
      _imageDedectionConfidence = 0.0f;
    }
  }
  return image;
}


- (void)setupCameraView
{
  _imageDedectionConfidence = 0.0;
  [super setupCameraView];
}

- (void)enableBorderDetectFrame
{
    _borderDetectFrame = YES;
}

- (CIImage *)drawHighlightOverlayForPoints:(CIImage *)image topLeft:(CGPoint)topLeft topRight:(CGPoint)topRight bottomLeft:(CGPoint)bottomLeft bottomRight:(CGPoint)bottomRight
{
    CIImage *overlay = [CIImage imageWithColor:[[CIColor alloc] initWithColor:self.overlayColor]];
    overlay = [overlay imageByCroppingToRect:image.extent];
    overlay = [overlay imageByApplyingFilter:@"CIPerspectiveTransformWithExtent" withInputParameters:@{@"inputExtent":[CIVector vectorWithCGRect:image.extent],@"inputTopLeft":[CIVector vectorWithCGPoint:topLeft],@"inputTopRight":[CIVector vectorWithCGPoint:topRight],@"inputBottomLeft":[CIVector vectorWithCGPoint:bottomLeft],@"inputBottomRight":[CIVector vectorWithCGPoint:bottomRight]}];

    return [overlay imageByCompositingOverImage:image];
}

- (void)start
{
  [super start];

  float detectionRefreshRate = _detectionRefreshRateInMS;
  CGFloat detectionRefreshRateInSec = detectionRefreshRate/100;

  if (_lastDetectionRate != _detectionRefreshRateInMS) {
    if (_borderDetectTimeKeeper) {
      [_borderDetectTimeKeeper invalidate];
    }
  _borderDetectTimeKeeper = [NSTimer scheduledTimerWithTimeInterval:detectionRefreshRateInSec target:self selector:@selector(enableBorderDetectFrame) userInfo:nil repeats:YES];
  }

  _lastDetectionRate = _detectionRefreshRateInMS;
}

- (void)stop
{
  [super stop];
    
  [_borderDetectTimeKeeper invalidate];
}

- (void)setDetectionRefreshRateInMS:(NSInteger)detectionRefreshRateInMS
{
    _detectionRefreshRateInMS = detectionRefreshRateInMS;
}

- (void)captureImageWithCompletionHander:(void(^)(UIImage *data, UIImage *initialData, CIRectangleFeature *rectangleFeature))completionHandler
{
  [super captureImageWithCompletionHander:^(CIImage* enhancedImage){
    int orientation = [self getOrientationForImage];

    if (self.isBorderDetectionEnabled && isRectangleDetectionConfidenceHighEnough(self->_imageDedectionConfidence))
    {
        CIRectangleFeature *rectangleFeature = [self biggestRectangleInRectangles:[[self highAccuracyRectangleDetector] featuresInImage:enhancedImage]];

        if (rectangleFeature)
        {
          CIImage *croppedImage = [self correctPerspectiveForImage:enhancedImage withFeatures:rectangleFeature];
          CGFloat rectHeight;
          CGFloat rectWidth;
          if ([self isPortraitOrientation]) {
            // Portrait Layout (height/width is normal)
            rectHeight = croppedImage.extent.size.height;
            rectWidth = croppedImage.extent.size.width;
          } else {
            // Landscape layout (height/width is reversed
            rectHeight = croppedImage.extent.size.width;
            rectWidth = croppedImage.extent.size.height;
          }
          
          UIGraphicsBeginImageContext(CGSizeMake(rectHeight, rectWidth));
          [
           [UIImage imageWithCIImage:croppedImage scale:1.0 orientation:orientation]
           drawInRect:CGRectMake(0,0, rectHeight, rectWidth)
          ];
          UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
          UIImage *initialImage = [UIImage imageWithCIImage:enhancedImage scale:1.0 orientation:orientation];
          UIGraphicsEndImageContext();
          completionHandler(image, initialImage, rectangleFeature);
        }
    } else {
        UIImage *initialImage = [UIImage imageWithCIImage:enhancedImage scale:1.0 orientation:orientation];
        completionHandler(initialImage, initialImage, nil);
    }
  }];
}

- (CIImage *)correctPerspectiveForImage:(CIImage *)image withFeatures:(CIRectangleFeature *)rectangleFeature
{
  NSMutableDictionary *rectangleCoordinates = [NSMutableDictionary new];
  CGPoint newLeft = CGPointMake(rectangleFeature.topLeft.x + 30, rectangleFeature.topLeft.y);
  CGPoint newRight = CGPointMake(rectangleFeature.topRight.x, rectangleFeature.topRight.y);
  CGPoint newBottomLeft = CGPointMake(rectangleFeature.bottomLeft.x + 30, rectangleFeature.bottomLeft.y);
  CGPoint newBottomRight = CGPointMake(rectangleFeature.bottomRight.x, rectangleFeature.bottomRight.y);


  rectangleCoordinates[@"inputTopLeft"] = [CIVector vectorWithCGPoint:newLeft];
  rectangleCoordinates[@"inputTopRight"] = [CIVector vectorWithCGPoint:newRight];
  rectangleCoordinates[@"inputBottomLeft"] = [CIVector vectorWithCGPoint:newBottomLeft];
  rectangleCoordinates[@"inputBottomRight"] = [CIVector vectorWithCGPoint:newBottomRight];
  
  return [image imageByApplyingFilter:@"CIPerspectiveCorrection" withInputParameters:rectangleCoordinates];
}

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

- (bool)isPortraitOrientation
{
  switch ([UIApplication sharedApplication].statusBarOrientation) {
  case UIDeviceOrientationPortrait:
      return true;
  case UIDeviceOrientationPortraitUpsideDown:
      return true;
  case UIDeviceOrientationLandscapeLeft:
      return false;
  case UIDeviceOrientationLandscapeRight:
      return false;
  default:
      return true;
  }
}

- (CIDetector *)rectangleDetetor
{
    static CIDetector *detector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
          detector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyLow,CIDetectorTracking : @(YES)}];
    });
    return detector;
}

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

- (CIRectangleFeature *)biggestRectangleInRectangles:(NSArray *)rectangles
{
    if (![rectangles count]) return nil;

    float halfPerimiterValue = 0;

    CIRectangleFeature *biggestRectangle = [rectangles firstObject];

    for (CIRectangleFeature *rect in rectangles)
    {
        CGPoint p1 = rect.topLeft;
        CGPoint p2 = rect.topRight;
        CGFloat width = hypotf(p1.x - p2.x, p1.y - p2.y);

        CGPoint p3 = rect.topLeft;
        CGPoint p4 = rect.bottomLeft;
        CGFloat height = hypotf(p3.x - p4.x, p3.y - p4.y);

        CGFloat currentHalfPerimiterValue = height + width;

        if (halfPerimiterValue < currentHalfPerimiterValue)
        {
            halfPerimiterValue = currentHalfPerimiterValue;
            biggestRectangle = rect;
        }
    }

    if (self.delegate) {
        [self.delegate didDetectRectangle:biggestRectangle withType:[self typeForRectangle:biggestRectangle]];
    }

    return biggestRectangle;
}

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

BOOL isRectangleDetectionConfidenceHighEnough(float confidence)
{
    return (confidence > 1.0);
}

@end
