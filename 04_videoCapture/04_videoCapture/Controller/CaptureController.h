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

#define SESSION_DEBUG_INFO 1
#define CaptureControllerErrorDomain @"com.sy.videoCapture"
#define CAMERA_ZOOM_CONTEXT @"CAMERA_ZOOM_CONTEXT"

typedef enum : NSUInteger {
    SessionConfigResultUnKnowed,
    SessionConfigResultUnAuthorized,
    SessionConfigResultSuccess,
    SessionConfigResultFailed,
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
    CaptureModeRealTimeFilterVideo,
} CaptureMode;


typedef enum : NSUInteger {
    LivePhotoModeUnkonwed,
    LivePhotoModeOn,
    LivePhotoModeOff,
} LivePhotoMode;


@interface PhotoCaptureData : NSObject

@property (strong, nonatomic) AVCapturePhotoSettings* captureSettings;
@property (strong, nonatomic) NSData* photoData;
@property (strong, nonatomic) NSURL* livePhotoMovieCompanionURL;

@end




@protocol CaptureControllerDelegate <NSObject>

@optional
//
// session configuration
//
- (void)captureController:(CaptureController * _Nullable )controller ConfigureSessionResult:(SessionConfigResult)result Error:(NSError* _Nullable)error;
- (void)captureController:(CaptureController *)controller ConfigureDevice:(AVCaptureDevice*)device FailedWithError:(NSError*)error;
- (void)captureControllerSessionRuntimeError:(CaptureController*)controller;
- (void)captureControllerSessionDidStartRunning:(CaptureController*)controller;
- (void)captureControllerSessionDidStopRunning:(CaptureController *)controller;
- (void)captureController:(CaptureController *)controller LeaveCaptureMode:(CaptureMode)mode;
- (void)captureController:(CaptureController *)controller EnterCaptureMode:(CaptureMode)mode;
//
// photo/video capture
//
- (void)captureController:(CaptureController *)controller InavailbleCaptureRequestForMode:(CaptureMode)mode;
- (void)captureController:(CaptureController *)controller WillCapturePhotoWithPhotoSessionID:(int64_t)Id;
- (void)captureController:(CaptureController *)controller BeginCapturePhotoWithPhotoSessionID:(int64_t)Id;
- (void)captureController:(CaptureController *)controller DidFinishCapturePhotoWithPhotoSessionID:(int64_t)Id Error:(NSError* _Nullable)error;
- (void)captureController:(CaptureController *)controller SaveCapturePhotoWithSessionID:(int64_t)Id ToLibraryWithResult:(AssetSavedResult)result Error:(NSError* _Nullable)error;
- (void)captureController:(CaptureController *)controller DidStartRecordingToFileURL:(NSURL*)url;
- (void)captureController:(CaptureController *)controller DidFinishRecordingToFileURL:(NSURL*)url Error:(NSError*)error;
- (void)captureController:(CaptureController *)controller SaveVideo:(NSURL* _Nullable)url ToLibraryWithResult:(AssetSavedResult)result Error:(NSError* _Nullable)error;
//- (void)captureController:(CaptureController *)controller DidCaptureVideoFrame:(CIImage*)image;
- (void)captureController:(CaptureController *)controller BeginRealTimeFilterVideoRecordSession:(BOOL)ready;
- (void)captureController:(CaptureController *)controller FinishRealTimeFilterVideoRecordSessionWithOutputURL:(NSURL* _Nullable)url Error:(NSError* _Nullable)error;
- (CIImage*)captureController:(CaptureController *)controller ExpectedProcessingFilterVideoFrame:(CIImage*)frame;

// device capbilities
- (void)captureControllerBeginSwitchCamera;
- (void)captureControllerDidFinishSwitchCamera:(BOOL)success;
- (void)captureController:(CaptureController *)controller DidCameraZoomToFactor:(CGFloat)factor;
- (void)captureController:(CaptureController*)controller WillSwitchFlashModeFrom:(AVCaptureFlashMode)mode;
- (void)captureController:(CaptureController*)controller DidSwitchFlashModeTo:(AVCaptureFlashMode)mode;
- (void)captureController:(CaptureController *)controller DidToggleLivePhotoModeTo:(LivePhotoMode)mode;

@required


@end


@interface CaptureController : NSObject
@property (readonly, nonatomic) AVCaptureSession* session;
@property (weak, nonatomic) id<CaptureControllerDelegate> delegate;
@property (readonly, nonatomic) BOOL recording; // whether session is currently recording video

@property (nonatomic, readonly) BOOL tapToFocusSupported;
@property (nonatomic) BOOL tapToFocusEnabled;

@property (nonatomic, readonly) BOOL tapToExposureSupported;
@property (nonatomic) BOOL tapToExposureEnabled;

@property (nonatomic, readonly) BOOL switchCameraSupported;
@property (nonatomic) BOOL switchCameraEnabled;

@property (nonatomic, readonly) BOOL cameraZoomSupported;
@property (nonatomic) BOOL cameraZoomEnabled;
@property (nonatomic, readonly) CGFloat cameraMinZoomFactor;
@property (nonatomic, readonly) CGFloat cameraMaxZoomFactor;
@property (nonatomic, readonly) CGFloat cameraZoomFactor;

@property (nonatomic, readonly) BOOL flashModeSwitchSupported;
@property (nonatomic) BOOL flashModeSwitchEnabled;
@property (nonatomic, readonly) AVCaptureFlashMode flashMode;

@property (nonatomic, readonly) BOOL livePhotoCaptureSupported;
@property (nonatomic) BOOL livePhotoCaptureEnabled;
@property (nonatomic, assign) LivePhotoMode livePhotoMode;
//
// configurate session
//
- (void)setupSessionWithCompletionHandle:(void(^)(void))completionHandler;
- (void)switchToMode:(CaptureMode)mode;
- (void)setPreviewLayer:(AVCaptureVideoPreviewLayer*)videoPreviewlayer;
- (void)startSession;
- (void)stopSession;
- (void)cleanUpSession;

//
// photo/video capture
//
- (void)capturePhoto;
- (void)startRecording;
- (void)stopRecording;

//
// device capability
//
- (void)tapToFocusAtInterestPoint:(CGPoint)point;
- (void)resetFocus;
- (void)tapToExposureAtInterestPoint:(CGPoint)point;
- (void)resetExposure;
- (void)switchCamera;
- (void)setVideoZoomWithFactor:(CGFloat)factor;
- (void)setVideoZoomWithPercent:(float)percent;
- (void)smoothZoomVideoTo:(CGFloat)zoomFactor WithRate:(float)rate;
- (void)cancelVideoSmoothZoom;
- (void)switchFlashMoe:(AVCaptureFlashMode)mode;

@end

NS_ASSUME_NONNULL_END
