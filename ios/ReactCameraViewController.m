/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The camera preview view that displays the capture output.
*/

@import AVFoundation;

#import "ReactCameraViewController.h"

@implementation ReactCameraViewController

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];

  NSLog(@"layout subviews?");
}

- (void) viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  NSLog(@"layout disappeared?");
}


@end
