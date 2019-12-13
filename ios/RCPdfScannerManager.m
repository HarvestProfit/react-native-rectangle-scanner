
#import "RCPdfScannerManager.h"
#import "RCDocumentScannerView.h"

@interface RCPdfScannerManager()
@property (strong, nonatomic) RCDocumentScannerView *scannerView;
@end

@implementation RCPdfScannerManager

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE(RCPdfScannerManager)

RCT_EXPORT_VIEW_PROPERTY(onPictureTaken, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onRectangleDetect, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onDeviceSetup, RCTBubblingEventBlock)


RCT_EXPORT_VIEW_PROPERTY(enableTorch, BOOL)
RCT_EXPORT_VIEW_PROPERTY(useFrontCam, BOOL)
RCT_EXPORT_VIEW_PROPERTY(useBase64, BOOL)
RCT_EXPORT_VIEW_PROPERTY(saveInAppDocument, BOOL)
RCT_EXPORT_VIEW_PROPERTY(captureOnDetect, BOOL)
RCT_EXPORT_VIEW_PROPERTY(detectionCountBeforeCapture, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(detectionRefreshRateInMS, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(quality, float)
RCT_EXPORT_VIEW_PROPERTY(filter, int)

RCT_EXPORT_METHOD(capture) {
    [_scannerView capture];
}

RCT_EXPORT_METHOD(start) {
    [_scannerView startCamera];
}

RCT_EXPORT_METHOD(stop) {
    [_scannerView stopCamera];
}

RCT_EXPORT_METHOD(cleanup) {
    [_scannerView cleanup];
}



- (UIView*) view {
    _scannerView = [[RCDocumentScannerView alloc] init];
    return _scannerView;
}

@end
