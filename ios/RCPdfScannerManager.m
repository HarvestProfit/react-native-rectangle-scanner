
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


RCT_EXPORT_VIEW_PROPERTY(overlayColor, UIColor)
RCT_EXPORT_VIEW_PROPERTY(enableTorch, BOOL)
RCT_EXPORT_VIEW_PROPERTY(useFrontCam, BOOL)
RCT_EXPORT_VIEW_PROPERTY(useBase64, BOOL)
RCT_EXPORT_VIEW_PROPERTY(saveInAppDocument, BOOL)
RCT_EXPORT_VIEW_PROPERTY(captureMultiple, BOOL)
RCT_EXPORT_VIEW_PROPERTY(detectionCountBeforeCapture, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(detectionRefreshRateInMS, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(saturation, float)
RCT_EXPORT_VIEW_PROPERTY(quality, float)
RCT_EXPORT_VIEW_PROPERTY(brightness, float)
RCT_EXPORT_VIEW_PROPERTY(contrast, float)

RCT_EXPORT_METHOD(capture) {

    [_scannerView capture];
}

- (UIView*) view {
  NSLog(@"PDF SCANNER");
    _scannerView = [[RCDocumentScannerView alloc] init];
    return _scannerView;
}

- (BOOL)shouldAutorotate
{
    return FALSE;
} 

@end
