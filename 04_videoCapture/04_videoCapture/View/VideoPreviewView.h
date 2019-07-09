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

@protocol VideoPreviewViewDelegate <NSObject>

- (void)tapToFocusAndExposureAtPoint:(CGPoint)point;
- (void)tapToResetFocusAndExposure;

@end

@interface VideoPreviewView : UIView

@property (strong, nonatomic) AVCaptureSession* captureSession;
@property (strong, readonly, nonatomic) AVCaptureVideoPreviewLayer* previewLayer;
@property (weak, nonatomic) id<VideoPreviewViewDelegate> delegate;
@property (assign, nonatomic) BOOL tapToFocusAndExposureEnabled;

@end

NS_ASSUME_NONNULL_END
