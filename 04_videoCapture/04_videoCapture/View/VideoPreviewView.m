//
//  SYVideoPreviewView.m
//  04_videoCapture
//
//  Created by sy on 2019/7/9.
//  Copyright © 2019 sy. All rights reserved.
//

#import "VideoPreviewView.h"


@interface VideoPreviewView ()

@end



@implementation VideoPreviewView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupView];
    }
    return self;
}

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (void)setupView {
    self.backgroundColor = [UIColor blackColor];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    return (AVCaptureVideoPreviewLayer*)self.layer;
}


- (void)setCaptureSession:(AVCaptureSession *)captureSession {
    self.previewLayer.session = captureSession;
}

- (AVCaptureSession *)captureSession {
    return self.previewLayer.session;
}


@end
