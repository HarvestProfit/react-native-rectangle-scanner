//
//  RNRectangleScannerManager.m
//
//  Created by Jake Humphrey on Jan 6, 2020.
//  Copyright (c) 2020 Jake Humphrey. All rights reserved.
//

#import "RNRectangleScannerManager.h"
#import "RNRectangleScannerView.h"

@interface RNRectangleScannerManager()
@property (strong, nonatomic) RNRectangleScannerView *scannerView;
@end

/*!
The React view manager. Exports props/methods to react
*/
@implementation RNRectangleScannerManager

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE(RNRectangleScannerManager)


/*!
 Turns on the flash light
 */
RCT_EXPORT_VIEW_PROPERTY(enableTorch, BOOL)

/*!
 The JPEG image quality of the final captured image (defaults to highest quality)
 */
RCT_EXPORT_VIEW_PROPERTY(capturedQuality, float)

/*!
 Determines what filter id to use (1, 2, 3, or 4)
 */
RCT_EXPORT_VIEW_PROPERTY(filterId, int)


// MARK: Life cycle Actions
/*!
 Starts the camera.  If not setup, it will set up the device as well.
 */
RCT_EXPORT_METHOD(start) {
  [_scannerView startCamera];
}

/*!
 Stops the camera. It does not call any cleanup actions though.
 */
RCT_EXPORT_METHOD(stop) {
  [_scannerView stopCamera];
}

/*!
 focuses the camera
 */
RCT_EXPORT_METHOD(focusCamera) {
  [_scannerView focusCamera];
}

/*!
 Cleans up any extra running camera stuff
 */
RCT_EXPORT_METHOD(cleanup) {
  [_scannerView cleanup];
}

/*!
 Stops the camera, reinitializes everything, and starts the camera.
 */
RCT_EXPORT_METHOD(refresh) {
  [_scannerView cleanup];
  [_scannerView startCamera];
}

/*!
 Starts taking a picture.  This triggers a few events
 */
RCT_EXPORT_METHOD(capture) {
    [_scannerView capture];
}

// MARK: Life cycle Events
/*!
 Called when the device is setup, the event contains information about permissions and camera capabilities
 */
RCT_EXPORT_VIEW_PROPERTY(onDeviceSetup, RCTDirectEventBlock)

/*!
 Called when the frame is captured.  This is before any processing and is only available in memory.
 */
RCT_EXPORT_VIEW_PROPERTY(onPictureTaken, RCTDirectEventBlock)

/*!
 Called when the captured frame is processed and saved to the temp file directory.
 */
RCT_EXPORT_VIEW_PROPERTY(onPictureProcessed, RCTDirectEventBlock)

/*!
 Called when a rectangle is detected
 */
RCT_EXPORT_VIEW_PROPERTY(onErrorProcessingImage, RCTDirectEventBlock)

/*!
 Called when a rectangle is detected
 */
RCT_EXPORT_VIEW_PROPERTY(onRectangleDetected, RCTDirectEventBlock)

/*!
 Called when the flash is turned off or on
 */
RCT_EXPORT_VIEW_PROPERTY(onTorchChanged, RCTDirectEventBlock)

- (UIView*) view {
  _scannerView = [[RNRectangleScannerView alloc] init];
  return _scannerView;
}

@end
