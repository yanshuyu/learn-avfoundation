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
    AssetSavedResultUnknowed,
    AssetSavedResultSuccess,
    AssetSavedResultFailed,
    AssetSavedResultUnAuthorized,
} AssetSavedResult;


typedef enum : NSUInteger {
    CaptureModeUnkonwed,
    CaptureModeVideo,
    CaptureModePhoto,
} CaptureMode;



@protocol CaptureControllerDelegate <NSObject>

@optional
//
// session configuration
//
- (void)captureController:(CaptureController * _Nullable )controller ConfigureSessionResult:(SessionConfigResult)result Error:(NSError* _Nullable)error;
- (void)captureControllerSessionRuntimeError:(CaptureController*)controller;
- (void)captureControllerSessionDidStartRunning:(CaptureController*)controller;
- (void)captureControllerSessionDidStopRunning:(CaptureController *)controller;
- (void)captureController:(CaptureController *)controller LeaveCaptureMode:(CaptureMode)mode;
- (void)captureController:(CaptureController *)controller EnterCaptureMode:(CaptureMode)mode;
//
// photo/video capture
//
- (void)captureController:(CaptureController *)controller InavailbleCaptureRequestForMode:(CaptureMode)mode;
- (void)captureController:(CaptureController *)controller WillCapturePhotoWithSettings:(AVCaptureResolvedPhotoSettings*)settings;
- (void)captureController:(CaptureController *)controller DidCapturePhotoWithSettings:(AVCaptureResolvedPhotoSettings *)settings;
- (void)captureController:(CaptureController *)controller DidFinishCapturePhotoWithSettings:(AVCaptureResolvedPhotoSettings *)settings Error:(NSError*)error;
- (void)captureController:(CaptureController *)controller SavePhoto:(NSData* _Nullable)data ToLibraryWithResult:(AssetSavedResult)result Error:(NSError* _Nullable)error;
- (void)captureController:(CaptureController *)controller DidStartRecordingToFileURL:(NSURL*)url;
- (void)captureController:(CaptureController *)controller DidFinishRecordingToFileURL:(NSURL*)url Error:(NSError*)error;
- (void)captureController:(CaptureController *)controller SaveVideo:(NSURL* _Nullable)url ToLibraryWithResult:(AssetSavedResult)result Error:(NSError* _Nullable)error;
@required


@end


@interface CaptureController : NSObject <VideoPreviewViewDelegate>

@property (weak, nonatomic) id<CaptureControllerDelegate> delegate;
@property (readonly, nonatomic) BOOL recording; // whether session is currently recording video
//
// configurate session
//
- (void)setupSessionWithCompletionHandle:(void(^)(void))completionHandler;
- (void)switchToMode:(CaptureMode)mode;
- (void)setPreviewLayer:(VideoPreviewView*)view;
- (void)startSession;
- (void)stopSession;
- (void)cleanUpSession;

//
// photo/video capture
//
- (void)capturePhoto;
- (void)startRecording;
- (void)stopRecording;


@end

NS_ASSUME_NONNULL_END
