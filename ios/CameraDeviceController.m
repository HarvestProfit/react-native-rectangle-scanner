//
//  CameraDeviceController.m
//
//  Created by Jake Humphrey on Jan 6, 2020.
//  Copyright (c) 2020 Jake Humphrey. All rights reserved.
//

#import "CameraDeviceController.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <GLKit/GLKit.h>

@interface CameraDeviceController () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate>

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
 @property cameraOutput
 @abstract
 Used for image capture output
 */
@property (nonatomic, strong) AVCapturePhotoOutput *cameraOutput;

@end


/*!
 Handles Generic camera device setup and capture
 */
@implementation CameraDeviceController
{
  GLuint _renderBuffer;
  GLKView *_glkView;
  NSMutableDictionary *_deviceConfiguration;
    dispatch_queue_t _captureImageQueue;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_backgroundMode) name:UIApplicationWillResignActiveNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_foregroundMode) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (instancetype)init {
  self = [super init];
  _captureImageQueue = dispatch_queue_create("CaptureImageQueue",NULL);

  // Keep track of the last device orientation for image orientation correction
  [self deviceOrientationDidChanged];
  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChanged) name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];

  return self;
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
 Set device orientation. It ignores orientations like "faceDown" so that the last real orientation is used.
 */
- (void)deviceOrientationDidChanged{
    _lastInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;

    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    // Ignore odd orientations, we only care about last real orientation
    if (deviceOrientation == UIDeviceOrientationFaceUp) return;
    if (deviceOrientation == UIDeviceOrientationFaceDown) return;
    if (deviceOrientation == UIDeviceOrientationUnknown) return;
    _lastDeviceOrientation = deviceOrientation;
}

/*!
 Toggles the flash on the camera device
 */
- (void)setEnableTorch:(BOOL)enableTorch
{
  _enableTorch = enableTorch;

  AVCaptureDevice *device = self.captureDevice;
  if ([device hasTorch] && [device hasFlash]) {
    [device lockForConfiguration:nil];
    if (enableTorch) {
      [device setTorchMode:AVCaptureTorchModeOn];
    } else {
      [device setTorchMode:AVCaptureTorchModeOff];
    }
    [device unlockForConfiguration];
  }

  [self torchWasChanged:enableTorch];
}

- (void)torchWasChanged:(BOOL)enableTorch {}


/*!
 Starts the capture session
 */
- (void)start
{
    self._isStopped = NO;
    dispatch_queue_t globalQueue =  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(globalQueue, ^{
      [self.captureSession startRunning];
    });
    [self hidePreviewLayerView:NO completion:nil];
}

/*!
 Stops the capture session
 */
- (void)stop
{
    self._isStopped = YES;
    dispatch_queue_t globalQueue =  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(globalQueue, ^{
      [self.captureSession stopRunning];
    });
    [self hidePreviewLayerView:YES completion:nil];
}

/*!
 Focuses the camera. This is a NoOp as iOS always continuously autofocuses. This can be used to later expand into
 focusing onto a specific point.
 */
- (void)focusCamera
{
    // NOOP
}

/*!
 Sets the currently active filter
 */
- (void)setFilterId:(int)filterId
{
  _filterId = filterId;
}

/*!
 Sets the device configuration flash setting
 */
- (void)_setDeviceConfigurationFlashAvailable: (BOOL) isAvailable{
  [_deviceConfiguration setValue:isAvailable ? @TRUE : @FALSE forKey:@"flashIsAvailable"];
}

/*!
 Sets the device configuration permission setting
 */
- (void)_setDeviceConfigurationPermissionToUseCamera: (BOOL) granted{
  [_deviceConfiguration setValue:granted ? @TRUE : @FALSE forKey:@"permissionToUseCamera"];
}

/*!
 Sets the device configuration camera availablility
 */
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
  [_deviceConfiguration setValue: @1.0 forKey: @"previewHeightPercent"];
  [_deviceConfiguration setValue: @1.0 forKey: @"previewWidthPercent"];
}

/*!
 Called after the camera and session are set up. This lets you check if a camera is found and permission is granted to use it.
 */
- (void)_commitDeviceConfiguration {
  [self deviceWasSetup:_deviceConfiguration];
}

- (void)deviceWasSetup:(NSDictionary *)config {}

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
 @return The orientation the image should be set to
 @note This will always return "right" if the device and the UI rotation match. Also, if the device is rotation locked, the device orientation will always be the same as the interface orientation.
 */
- (UIImageOrientation)getOrientationForImage
{
    if (_lastInterfaceOrientation == UIInterfaceOrientationPortrait) {
        if (_lastDeviceOrientation == UIDeviceOrientationLandscapeLeft) return UIImageOrientationUp;
        if (_lastDeviceOrientation == UIDeviceOrientationLandscapeRight) return UIImageOrientationDown;
        if (_lastDeviceOrientation == UIDeviceOrientationPortraitUpsideDown) return UIImageOrientationLeft;
    }

    if (_lastInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        if (_lastDeviceOrientation == UIDeviceOrientationLandscapeLeft) return UIImageOrientationUp;
        if (_lastDeviceOrientation == UIDeviceOrientationLandscapeRight) return UIImageOrientationDown;
        if (_lastDeviceOrientation == UIDeviceOrientationPortrait) return UIImageOrientationLeft;
    }

    // device landscape left == interface landscape right
    if (_lastInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        if (_lastDeviceOrientation == UIDeviceOrientationLandscapeLeft) return UIImageOrientationLeft;
        if (_lastDeviceOrientation == UIDeviceOrientationPortrait) return UIImageOrientationUp;
        if (_lastDeviceOrientation == UIDeviceOrientationPortraitUpsideDown) return UIImageOrientationDown;
    }

    // device landscape right == interface landscape left
    if (_lastInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        if (_lastDeviceOrientation == UIDeviceOrientationLandscapeRight) return UIImageOrientationLeft;
        if (_lastDeviceOrientation == UIDeviceOrientationPortrait) return UIImageOrientationDown;
        if (_lastDeviceOrientation == UIDeviceOrientationPortraitUpsideDown) return UIImageOrientationUp;
    }

    return UIImageOrientationRight;
}

/*!
 @return The view that is used to preview the camera output
 */
- (UIView *)getPreviewLayerView
{
  return _glkView;
}

- (CGRect)getBounds{
  return self.bounds;
}

/*!
 Gets the orientation that the image should be set to before cropping and transforming
 */
- (int)getCGImageOrientationForCaptureImage
{
  switch ([UIApplication sharedApplication].statusBarOrientation) {
    case UIDeviceOrientationPortrait:
        return kCGImagePropertyOrientationUp;
    case UIDeviceOrientationPortraitUpsideDown:
        return kCGImagePropertyOrientationDown;
    case UIDeviceOrientationLandscapeLeft:
        return kCGImagePropertyOrientationLeft;
    case UIDeviceOrientationLandscapeRight:
        return kCGImagePropertyOrientationRight;
    default:
        return kCGImagePropertyOrientationUp;
    }
}


/*!
 Gets a hardware camera device.
 @return A camera hardware object or nil if not found
 */
- (AVCaptureDevice *)getCameraDevice{
  AVCaptureDevice* possibleDevice;
  possibleDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
  if (possibleDevice) return possibleDevice;

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
  self._cameraIsSetup = YES;
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
  self.cameraOutput = [[AVCapturePhotoOutput alloc] init];
  [self.captureSession addOutput:self.cameraOutput];

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

- (BOOL)isLandscapeOrientation:(int) orientation {
  if (orientation == AVCaptureVideoOrientationPortrait || orientation == AVCaptureVideoOrientationPortraitUpsideDown) return YES;
  return NO;
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


  // Crop to fit screen
  CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(self.bounds.size.width, self.bounds.size.height), image.extent);
  image = [image imageByCroppingToRect:cropRect];

  image = [self processOutput:image];

  if (self.context && self._coreImageContext)
  {
    [self._coreImageContext drawImage:image inRect:self.bounds fromRect:image.extent];
    [self.context presentRenderbuffer:GL_RENDERBUFFER];

    [_glkView setNeedsDisplay];
  }
}

// MARK: Capture Image

-(void)handleCapturedImage:(CIImage *)capturedImage orientation: (UIImageOrientation) orientation {
}

/*!
 Responds to the capture Output call via delegate. It will apply a few filters and call handleCapturedImage which can be overrided for more processing
 */
-(void)captureOutput:(AVCapturePhotoOutput *)photo didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error
{
  if (error) {
    NSLog(@"error : %@", error.localizedDescription);
  }

  if (photoSampleBuffer) {
    NSData *imageData = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];

    CIImage *intialImage = [CIImage imageWithData:imageData];
    intialImage = [intialImage imageByApplyingOrientation:[self getCGImageOrientationForCaptureImage]];

    // Lock in the final image orientation
    UIImageOrientation imageOutputOrientation = [self getOrientationForImage];

    // Crop to fit screen size
    CGSize screenSize = CGSizeMake(self.bounds.size.height, self.bounds.size.width);
    CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(screenSize, intialImage.extent);

    intialImage = [intialImage imageByCroppingToRect:cropRect];
    intialImage = [intialImage imageByApplyingTransform:CGAffineTransformMakeTranslation(-intialImage.extent.origin.x, -intialImage.extent.origin.y)];

    [self setEnableTorch: NO];
    dispatch_async(_captureImageQueue, ^{
      CIImage *enhancedImage = [self applyFilters:intialImage];
      self._isCapturing = NO;
      [self handleCapturedImage:enhancedImage orientation: imageOutputOrientation];
    });
  }
}

/*!
 Triggers a capture from the photo output
 */
- (void)captureImageLater
{
  if (self._isCapturing) return;
  self._isCapturing = YES;

  AVCapturePhotoSettings *settings = [[AVCapturePhotoSettings alloc] init];
  NSNumber *previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.firstObject;

  NSString *formatTypeKey = (NSString *)kCVPixelBufferPixelFormatTypeKey;
  NSString *widthKey = (NSString *)kCVPixelBufferWidthKey;
  NSString *heightKey = (NSString *)kCVPixelBufferHeightKey;

  NSDictionary *previewFormat = @{formatTypeKey:previewPixelType,
                                  widthKey:@1024,
                                  heightKey:@768
                                  };

  settings.previewPhotoFormat = previewFormat;
  [self.cameraOutput capturePhotoWithSettings:settings delegate:self];
}

// MARK: Filters

/*!
 Applies filters to the CIImage based on configuration
 */
- (CIImage *)applyFilters:(CIImage *)image{
  switch (self.filterId) {
    case 1: return image;
    case 2: return [self applyGreyScaleFilterToImage:image];
    case 3: return [self applyColorFilterToImage:image];
    case 4: return [self applyBlackAndWhiteFilterToImage:image];
    default: return image;
  }
}

/*!
 Adds a black and white filter over the image
 */
- (CIImage *)applyGreyScaleFilterToImage:(CIImage *)image
{
  return [CIFilter filterWithName:@"CIColorControls" keysAndValues:kCIInputImageKey, image, kCIInputBrightnessKey, @(0), kCIInputContrastKey, @(1), kCIInputSaturationKey, @(0), nil].outputImage;
}

/*!
 Adds a black and white filter that bumps up the clarity of edges
 */
- (CIImage *)applyBlackAndWhiteFilterToImage:(CIImage *)image
{
  return [CIFilter filterWithName:@"CIColorControls" keysAndValues:kCIInputImageKey, image, kCIInputBrightnessKey, @(0.4), kCIInputContrastKey, @(2), kCIInputSaturationKey, @(0), nil].outputImage;
}

/*!
 Adds a color filter that bumps up the clarity of edges
 */
- (CIImage *)applyColorFilterToImage:(CIImage *)image
{
  return [CIFilter filterWithName:@"CIColorControls" keysAndValues:kCIInputImageKey, image, kCIInputBrightnessKey, @(0.35), kCIInputContrastKey, @(1.9), kCIInputSaturationKey, @(0.75), nil].outputImage;
}

@end
