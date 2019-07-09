//
//  SYCaptureViewController.m
//  04_videoCapture
//
//  Created by sy on 2019/7/9.
//  Copyright © 2019 sy. All rights reserved.
//

#import "SYCaptureViewController.h"
#import "../View/VideoPreviewView.h"
#import "../Controller/CaptureController.h"

@interface SYCaptureViewController () <CaptureControllerDelegate>

@property (weak, nonatomic) IBOutlet VideoPreviewView *videoPreviewView;


@property (strong, nonatomic) CaptureController* captureController;

@end

@implementation SYCaptureViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.captureController = [CaptureController new];
    NSError* e;
    if ([self.captureController setupCaptureSessionWithPreset:AVCaptureSessionPresetHigh
                                                        Error:&e]) {
        [self.captureController setPreviewLayer:self.videoPreviewView];
        [self.captureController startSession];
    }
}


- (void)captureController:(CaptureController*)controller ConfigureSessionFailedWithError:(NSError*)error {
    NSLog(@"session configruation error: %@", error.localizedDescription);
}


- (BOOL)prefersStatusBarHidden {
    return TRUE;
}

@end
