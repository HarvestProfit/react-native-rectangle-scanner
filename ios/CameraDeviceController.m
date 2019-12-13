//
//  IPDFCameraViewController.m
//  InstaPDF
//
//  Created by Maximilian Mackh on 06/01/15.
//  Copyright (c) 2015 mackh ag. All rights reserved.
//

#import "CameraDeviceController.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <GLKit/GLKit.h>

@interface CameraDeviceController () <AVCaptureVideoDataOutputSampleBufferDelegate>

/*!
@property session
@abstract
The capture session used for scanning documents.
*/
@property (nonatomic,strong) AVCaptureSession *captureSession;

/*!
@property captureDevice
@abstract
Represents the physical device that is used (back camera for example).
*/
@property (nonatomic,strong) AVCaptureDevice *captureDevice;

/*!
@property deviceInput
@abstract
Represents the input from the camera device
*/
@property (nonatomic, strong) AVCaptureDeviceInput* deviceInput;

/*!
 @property stillImageOutput
 @abstract
 Used for still image capture
 */
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;

@end


/*!
 Handles Generic camera device setup and capture
 */
@implementation CameraDeviceController
{
  GLuint _renderBuffer;
  GLKView *_glkView;
  NSMutableDictionary *_deviceConfiguration;
}

- (instancetype)init {
  self = [super init];
  [self setupCameraView];
  [self start];
  return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_backgroundMode) name:UIApplicationWillResignActiveNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_foregroundMode) name:UIApplicationDidBecomeActiveNotification object:nil];
}

/*!
 Called When the app enters the background
*/
- (void)_backgroundMode
{
  self.forceStop = YES;
  [self setEnableTorch: NO];
}

/*!
 Called When the app enters the foreground
*/
- (void)_foregroundMode
{
  self.forceStop = NO;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// MARK: Setters
/*!
 Toggles the flash on the camera device
 */
- (void)setEnableTorch:(BOOL)enableTorch
{
    _enableTorch = enableTorch;

    AVCaptureDevice *device = self.captureDevice;
    if ([device hasTorch] && [device hasFlash])
    {
        [device lockForConfiguration:nil];
        if (enableTorch)
        {
            [device setTorchMode:AVCaptureTorchModeOn];
        }
        else
        {
            [device setTorchMode:AVCaptureTorchModeOff];
        }
        [device unlockForConfiguration];
    }
}

/*!
 Starts the capture session
 */
- (void)start
{
    self._isStopped = NO;
    [self.captureSession startRunning];
    [self hidePreviewLayerView:NO completion:nil];
}

/*!
 Stops the capture session
 */
- (void)stop
{
    self._isStopped = YES;
    [self.captureSession stopRunning];
    [self hidePreviewLayerView:YES completion:nil];
}

/*!
 Uses the front camera
 */
- (void)setUseFrontCam:(BOOL)useFrontCam
{
  _useFrontCam = useFrontCam;
  if (self._isStopped == NO) {
    [self stop];
    [self setupCameraView];
    [self start];
  }
}

- (void)setFilter:(int)filter
{
  _filter = filter;
}

- (void)_setDeviceConfigurationFlashAvailable: (BOOL) isAvailable{
  [_deviceConfiguration setValue:isAvailable ? @TRUE : @FALSE forKey:@"flashIsAvailable"];
}

- (void)_setDeviceConfigurationPermissionToUseCamera: (BOOL) granted{
  [_deviceConfiguration setValue:granted ? @TRUE : @FALSE forKey:@"permissionToUseCamera"];
}

- (void)_setDeviceConfigurationHasCamera: (BOOL) isAvailable{
  [_deviceConfiguration setValue:isAvailable ? @TRUE : @FALSE forKey:@"hasCamera"];
}

/*!
 Sets the inital device configuration
 */
- (void)_resetDeviceConfiguration
{
  _deviceConfiguration = [[NSMutableDictionary alloc] init];
  [self _setDeviceConfigurationFlashAvailable:NO];
  [self _setDeviceConfigurationPermissionToUseCamera:NO ];
  [self _setDeviceConfigurationHasCamera:NO];
  
  [_deviceConfiguration setObject: [NSArray arrayWithObjects:[self getColorFilter], [self getGreyScaleFilter], [self getBlackAndWHiteFilter], [self getPhotoFilter], nil] forKey:@"availableFilters"];
}

- (void)_commitDeviceConfiguration {
  [self deviceDidSetup:_deviceConfiguration];
}

- (void)deviceDidSetup:(NSDictionary*) config {};

/*!
 Used to hide the output capture session preview layer
 */
- (void)hidePreviewLayerView:(BOOL)hidden completion:(void(^)(void))completion
{
    [UIView animateWithDuration:0.1 animations:^
    {
      self->_glkView.alpha = (hidden) ? 0.0 : 1.0;
    }
    completion:^(BOOL finished)
    {
        if (!completion) return;
        completion();
    }];
}

// MARK: Getters

/*!
 @return The view that is used to preview the camera output
 */
- (UIView *)getPreviewLayerView
{
  return _glkView;
}

- (NSDictionary *)getColorFilter{
  return @{
    @"name": @"Color",
    @"id": @1
  };
}

- (NSDictionary *)getGreyScaleFilter{
  return @{
    @"name": @"Greyscale",
    @"id": @2
  };
}

- (NSDictionary *)getBlackAndWHiteFilter{
  return @{
    @"name": @"Black & White",
    @"id": @3
  };
}

- (NSDictionary *)getPhotoFilter{
  return @{
    @"name": @"Photo",
    @"id": @4
  };
}

- (CGRect)getBounds{
  return self.bounds;
}


/*!
 Gets a hardware camera device.  If useFrontCam is true, it will find the front camera
 @return A camera hardware object or nil if not found
 */
- (AVCaptureDevice *)getCameraDevice{
  NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
  for (AVCaptureDevice *possibleDevice in devices) {
    if (self.useFrontCam) {
      if ([possibleDevice position] == AVCaptureDevicePositionFront) return possibleDevice;
    } else {
      if ([possibleDevice position] != AVCaptureDevicePositionFront) return possibleDevice;
    }
  }
  return nil;
}

// MARK: Setup

/*!
 Creates a session for the camera device and outputs it to a preview view.
 @note Called on view did load
 */
- (void)setupCameraView
{
  [self createPreviewViewLayer];
  [self _resetDeviceConfiguration];
  [self setupCamera];
  [self _commitDeviceConfiguration];
  [self listenForOrientationChanges];
}

/*!
 Creates the preview layer view for the camera output.
 @discussion
 Produces a GLKView which the camera output is drawn on.  There is a possibility that we could switch
 to an AVCaptureVideoPreviewLayer instead.  This is supposed to handle screen rotation better from what
 I've seen. This is how Apple's AVCam project does it as well.
 */
- (void)createPreviewViewLayer
{
    if (self.context) return;

    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    GLKView *view = [[GLKView alloc] initWithFrame:self.bounds];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.translatesAutoresizingMaskIntoConstraints = YES;
    view.context = self.context;
    view.contentScaleFactor = 1.0f;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [self insertSubview:view atIndex:0];
    _glkView = view;
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    self._coreImageContext = [CIContext contextWithEAGLContext:self.context];
    [EAGLContext setCurrentContext:self.context];
}

/*!
 Sets up the hardware and capture session asking for permission to use the camera if needed.
 */
- (void)setupCamera {
  if (![self setupCaptureDevice]) return;
  if (![self setupInputCaptureFromDevice]) return;
  
  // Set up the capture session from the input
  self.captureSession = [[AVCaptureSession alloc] init];
  [self.captureSession beginConfiguration];
  self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
  [self.captureSession addInput:self.deviceInput];

  // Output session capture to queue
  AVCaptureVideoDataOutput *dataOutput = [[AVCaptureVideoDataOutput alloc] init];
  [dataOutput setAlwaysDiscardsLateVideoFrames:YES];
  [dataOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)}];
  [dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
  [self.captureSession addOutput:dataOutput];

  // Output session capture to still image output
  self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
  [self.captureSession addOutput:self.stillImageOutput];

  // Correct the orientation of the output
  [self setVideoOrientation];
  
  [self.captureSession commitConfiguration];
}

/*!
 Finds a physical camera, configures it, and sets the captureDevice property to it
 @return The captureDevice property value (If falsey, could not find a valid camera)
 */
- (AVCaptureDevice *)setupCaptureDevice{
  self.captureDevice = [self getCameraDevice];
  if (!self.captureDevice) return nil;
  [self _setDeviceConfigurationHasCamera:YES];
  [self _setDeviceConfigurationFlashAvailable:([self.captureDevice hasTorch] && [self.captureDevice hasFlash])];
  
  // Setup camera focus mode
  if ([self.captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
  {
    [self.captureDevice lockForConfiguration:nil];
    [self.captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
    [self.captureDevice unlockForConfiguration];
  }
  
  // Setup camera flash mode
  if (self.captureDevice.isFlashAvailable)
  {
    [self.captureDevice lockForConfiguration:nil];
    [self.captureDevice setFlashMode:AVCaptureFlashModeOff];
    [self.captureDevice unlockForConfiguration];
  }
  return self.captureDevice;
}

/*!
 Gets input from the device (will ask for permission) and sets the deviceInput property.
 @return The deviceInput property value (If falsey, permission is not granted)
 */
- (AVCaptureDeviceInput *) setupInputCaptureFromDevice{
  NSError *error = nil;
  self.deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];
  [self _setDeviceConfigurationPermissionToUseCamera:self.deviceInput];
  return self.deviceInput;
}

// MARK: Orientation

/*!
 Sets the current capture session output orientation to the device's orientation
 */
- (void)setVideoOrientation {
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  AVCaptureVideoOrientation videoOrientation;
  switch (orientation) {
    case UIInterfaceOrientationPortrait:
      videoOrientation = AVCaptureVideoOrientationPortrait;
      break;
    case UIInterfaceOrientationPortraitUpsideDown:
      videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
      break;
    case UIInterfaceOrientationLandscapeLeft:
      videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
      break;
    case UIInterfaceOrientationLandscapeRight:
      videoOrientation = AVCaptureVideoOrientationLandscapeRight;
      break;
    default:
      videoOrientation = AVCaptureVideoOrientationPortrait;
  }
  
  [[[self.captureSession.outputs firstObject].connections firstObject] setVideoOrientation:videoOrientation];
}

/*!
 Listens for device orientation changes.  On change, it will change the orientation of the video preview output
 */
- (void)listenForOrientationChanges {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationDidChangeStatusBarNotification:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}

/*!
 Reponds to status bar orientation change events
 */
- (void)handleApplicationDidChangeStatusBarNotification:(NSNotification *)notification {
    [self setVideoOrientation];
}

// MARK: Auto Focus
/*!
 Focuses on a point of interest where the user tapped.
 */
- (void)focusAtPoint:(CGPoint)point completionHandler:(void(^)(void))completionHandler
{
  AVCaptureDevice *device = self.captureDevice;
  CGPoint pointOfInterest = CGPointZero;
  CGSize frameSize = self.bounds.size;
  pointOfInterest = CGPointMake(point.y / frameSize.height, 1.f - (point.x / frameSize.width));

  if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus])
  {
    NSError *error;
    if ([device lockForConfiguration:&error])
    {
      if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
      {
        [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        [device setFocusPointOfInterest:pointOfInterest];
      }

      if([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
      {
        [device setExposurePointOfInterest:pointOfInterest];
        [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        completionHandler();
      }

      [device unlockForConfiguration];
    }
  }
  else
  {
    completionHandler();
  }
}

// MARK: previewLayer Output

/*!
 Processes the image output from the capture session.
 @note Override this method to add additional processing
 */
-(CIImage *)processOutput:(CIImage *)image
{
  return [self applyFilters:image];
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
  if (self.forceStop) return;
  if (self._isStopped || self._isCapturing || !CMSampleBufferIsValid(sampleBuffer)) return;

  CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);

  CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
  
  image = [self processOutput:image];
  float rectHeight = image.extent.size.height;
  float rectWidth = image.extent.size.width;
  
//  CGRect imageRectangle = CGRectMake(0,0, rectHeight, rectWidth);
  CGRect imageRectangle = self.bounds;
  
  if (self.context && self._coreImageContext)
  {
    [self._coreImageContext drawImage:image inRect:imageRectangle fromRect:image.extent];
    [self.context presentRenderbuffer:GL_RENDERBUFFER];

    [_glkView setNeedsDisplay];
  }
}

// MARK: Capture Image

/*!
 Captures the current output from the capture session, applies some filters, and sends the CIImage to a completionHandler
 */
- (void)captureImageWithCompletionHander:(void(^)(CIImage* enhancedImage))completionHandler
{
  if (self._isCapturing) return;

  AVCaptureConnection *videoConnection = nil;
  for (AVCaptureConnection *connection in self.stillImageOutput.connections)
  {
    for (AVCaptureInputPort *port in [connection inputPorts])
    {
      if ([[port mediaType] isEqual:AVMediaTypeVideo] )
      {
        videoConnection = connection;
        break;
      }
    }
    if (videoConnection) break;
  }
  
  NSLog(@"Video Conn?");
  if (!videoConnection) return;
  NSLog(@"Video Conn FOUND");
  [self hidePreviewLayerView:YES completion:nil];
  self._isCapturing = YES;
  NSLog(@"Pre Capture");
  [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
  {
    NSLog(@"Capture Async");    
    NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
    CIImage *enhancedImage = [CIImage imageWithData:imageData];
    
    enhancedImage = [self applyFilters:enhancedImage];

    [self hidePreviewLayerView:NO completion:nil];
    NSLog(@"Capture Complete");
    completionHandler(enhancedImage);
    self._isCapturing = NO;
  }];
}

// MARK: Filters

/*!
 Applies filters to the CIImage based on configuration
 */
- (CIImage *)applyFilters:(CIImage *)image{
  if (self.filter == 2) return [self applyGreyScaleFilterToImage:image];
  if (self.filter == 3) return [self applyBlackAndWhiteFilterToImage:image];
  if (self.filter == 4) return image;
  return [self applyColorFilterToImage:image];
}

/*!
 Adds a black and white filter to the image that can be adjusted by setting the intensity property
 */
- (CIImage *)applyGreyScaleFilterToImage:(CIImage *)image
{
  return [CIFilter filterWithName:@"CIColorControls" keysAndValues:kCIInputImageKey, image, kCIInputBrightnessKey, @(0), kCIInputContrastKey, @(1), kCIInputSaturationKey, @(0), nil].outputImage;
}

/*!
 Adds a black and white filter to the image that can be adjusted by setting the intensity property
 */
- (CIImage *)applyBlackAndWhiteFilterToImage:(CIImage *)image
{
  return [CIFilter filterWithName:@"CIColorControls" keysAndValues:kCIInputImageKey, image, kCIInputBrightnessKey, @(0.4), kCIInputContrastKey, @(2), kCIInputSaturationKey, @(0), nil].outputImage;
}

/*!
 Adds a black and white filter to the image that can be adjusted by setting the intensity property
 */
- (CIImage *)applyColorFilterToImage:(CIImage *)image
{
  return [CIFilter filterWithName:@"CIColorControls" keysAndValues:kCIInputImageKey, image, kCIInputBrightnessKey, @(0.35), kCIInputContrastKey, @(1.9), kCIInputSaturationKey, @(0.75), nil].outputImage;
}

- (CIImage *)detectionFilter:(CIImage *)image {
  return [CIFilter filterWithName:@"CIColorControls" keysAndValues:kCIInputImageKey, image, kCIInputBrightnessKey, @(0.6), kCIInputContrastKey, @(2), kCIInputSaturationKey, @(2), nil].outputImage;
}

@end
