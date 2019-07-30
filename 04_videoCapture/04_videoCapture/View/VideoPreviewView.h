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


@interface VideoPreviewView : UIView

@property (weak, nonatomic) AVCaptureSession* captureSession;
@property (strong, readonly, nonatomic) AVCaptureVideoPreviewLayer* previewLayer;

@end

NS_ASSUME_NONNULL_END
