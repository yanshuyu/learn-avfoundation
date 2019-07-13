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

#define SESSION_DEBUG_INFO 1

@class CaptureController;

#define CaptureControllerErrorDomain @"com.sy.videoCapture"

typedef enum : NSUInteger {
    SessionSetupResultUnKnowed,
    SessionSetupResultUnAuthorized,
    SessionSetupResultSuccess,
    SessionSetupResultFailed,
} SessionConfigResult;


typedef enum : NSUInteger {
    CaptureModeUnkonwed,
    CaptureModeVideo,
    CaptureModePhoto,
} CaptureMode;


@protocol CaptureControllerDelegate <NSObject>

@optional
- (void)captureController:(CaptureController * _Nullable )controller ConfigureSessionResult:(SessionConfigResult)result Error:(NSError* _Nullable)error;
- (void)captureControllerSessionRuntimeError:(CaptureController*)controller;
- (void)captureControllerSessionDidStartRunning:(CaptureController*)controller;
- (void)captureControllerSessionDidStopRunning:(CaptureController *)controller;
- (void)captureController:(CaptureController *)controller LeaveCaptureMode:(CaptureMode)mode;
- (void)captureController:(CaptureController *)controller EnterCaptureMode:(CaptureMode)mode;


@required


@end


@interface CaptureController : NSObject <VideoPreviewViewDelegate>

@property (weak, nonatomic) id<CaptureControllerDelegate> delegate;
//
// configurate session
//
- (void)setupSessionWithCompletionHandle:(void(^)(void))completionHandler;
- (void)switchToMode:(CaptureMode)mode;
- (void)setPreviewLayer:(VideoPreviewView*)view;
- (void)startSession;
- (void)stopSession;
- (void)cleanUpSession;

@end

NS_ASSUME_NONNULL_END
