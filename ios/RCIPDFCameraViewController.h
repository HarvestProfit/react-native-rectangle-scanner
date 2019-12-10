//
//  IPDFCameraViewController.h
//  InstaPDF
//
//  Created by Maximilian Mackh on 06/01/15.
//  Copyright (c) 2015 mackh ag. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,RCIPDFCameraViewType)
{
    RCIPDFCameraViewTypeBlackAndWhite,
    RCIPDFCameraViewTypeNormal
};

typedef NS_ENUM(NSInteger, RCIPDFRectangeType)
{
    RCIPDFRectangeTypeGood,
    RCIPDFRectangeTypeBadAngle,
    RCIPDFRectangeTypeTooFar
};

@protocol RCIPDFCameraViewControllerDelegate <NSObject>

- (void) didDetectRectangle: (CIRectangleFeature*) rectangle withType: (RCIPDFRectangeType) type;

@end

@interface RCIPDFCameraViewController : UIView

- (void)setupCameraView;

- (void)start;
- (void)stop;

@property (nonatomic,assign,getter=isBorderDetectionEnabled) BOOL enableBorderDetection;
@property (nonatomic,assign,getter=isTorchEnabled) BOOL enableTorch;
@property (nonatomic,assign,getter=isFrontCam) BOOL useFrontCam;

@property (weak, nonatomic) id<RCIPDFCameraViewControllerDelegate> delegate;

@property (nonatomic,assign) RCIPDFCameraViewType cameraViewType;

- (void)focusAtPoint:(CGPoint)point completionHandler:(void(^)())completionHandler;

- (void)captureImageWithCompletionHander:(void(^)(UIImage *data, UIImage *initialData, CIRectangleFeature *rectangleFeature))completionHandler;

@property (nonatomic, strong) UIColor* overlayColor;
@property (nonatomic, assign) float saturation;
@property (nonatomic, assign) float contrast;
@property (nonatomic, assign) float brightness;
@property (nonatomic, assign) NSInteger detectionRefreshRateInMS;


@end
