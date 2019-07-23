//
//  SYVideoPreviewView.h
//  04_videoCapture
//
//  Created by sy on 2019/7/9.
//  Copyright © 2019 sy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class VideoPreviewView;

@protocol VideoPreviewViewDelegate <NSObject>

@optional
- (void)videoPreviewView:(VideoPreviewView*)view TapToFocusAndExposureAtPoint:(CGPoint)point;
- (void)videoPreviewView:(VideoPreviewView*)view TapToResetFocusAndExposure:(CGPoint)point;
- (void)videoPreviewView:(VideoPreviewView*)view BeginCameraZoom:(CGFloat)scale;
- (void)videoPreviewView:(VideoPreviewView *)view CameraZooming:(CGFloat)scale;
- (void)videoPreviewView:(VideoPreviewView *)view DidFinishCameraZoom:(CGFloat)scale;

@end

@interface VideoPreviewView : UIView

@property (strong, nonatomic) AVCaptureSession* captureSession;
@property (strong, readonly, nonatomic) AVCaptureVideoPreviewLayer* previewLayer;
@property (weak, nonatomic) id<VideoPreviewViewDelegate> delegate;
@property (assign, nonatomic) BOOL tapToFocusAndExposureEnabled;
@property (nonatomic) BOOL pinchToZoomCameraEnabled;

@end

NS_ASSUME_NONNULL_END
