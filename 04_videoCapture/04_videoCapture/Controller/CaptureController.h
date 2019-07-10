//
//  SYCaptureController.h
//  04_videoCapture
//
//  Created by sy on 2019/7/9.
//  Copyright © 2019 sy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "../View/VideoPreviewView.h"

NS_ASSUME_NONNULL_BEGIN

@class CaptureController;

#define CaptureControllerErrorDomain @"com.sy.videoCapture"

typedef enum : NSUInteger {
    CaptureControllerErrorIncompatibleDeviceInput,
    CaptureControllerErrorIncompatibleDeviceOutput,
} CaptureControllerError;


@protocol CaptureControllerDelegate <NSObject>

- (void)captureController:(CaptureController*)controller ConfigureSessionFailedWithError:(NSError*)error;


@end


@interface CaptureController : NSObject <VideoPreviewViewDelegate>

@property (weak, nonatomic) id<CaptureControllerDelegate> delegate;

//
// configurate session
//
- (BOOL)setupCaptureSessionWithPreset:(AVCaptureSessionPreset)preset Error:(NSError* _Nullable*)error;
- (void)setPreviewLayer:(VideoPreviewView*)view;
- (void)startSession;
- (void)stopSession;

@end

NS_ASSUME_NONNULL_END