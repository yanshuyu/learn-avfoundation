//
//  SYCaptureController.m
//  04_videoCapture
//
//  Created by sy on 2019/7/9.
//  Copyright © 2019 sy. All rights reserved.
//

#import "CaptureController.h"
#import <Photos/Photos.h>

@interface CaptureController () <AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate>
//
// session configuration
//
@property (strong, nonatomic) AVCaptureSession* session;
@property (strong, nonatomic) AVCaptureDeviceDiscoverySession* discoverySession;
@property (weak, nonatomic) AVCaptureVideoPreviewLayer* videoPreviewLayer;
@property (strong, nonatomic) AVCaptureDeviceInput* videoDeviceInput;
@property (strong, nonatomic) AVCaptureDeviceInput* audioDeviceInput;
@property (strong, nonatomic) AVCaptureMovieFileOutput* movieOutput;
@property (strong, nonatomic) AVCapturePhotoOutput* photoOutput;
@property (nonatomic) CaptureMode currentCaptureMode;
@property (strong, nonatomic) dispatch_queue_t sessionQueue;

//
// photo/video capture
//
@property (strong, nonatomic) NSMutableDictionary* photoCaptureSettingsOnProgressing;
@property (strong, nonatomic) NSMutableDictionary* photoCaptureDataOnProgressing;

//
// device capbilites
//
@property (nonatomic) AVCaptureFlashMode flashMode;

@end


@implementation CaptureController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.session = [AVCaptureSession new];
        [self addSessionObserver];
        self.currentCaptureMode = CaptureModeUnkonwed;
        self.sessionQueue = dispatch_queue_create("com.sy.learn-avfoundation.video-capture", DISPATCH_QUEUE_SERIAL);
        self.photoCaptureSettingsOnProgressing = [NSMutableDictionary new];
        self.photoCaptureDataOnProgressing = [NSMutableDictionary new];
    }
    return self;
}

- (void)captureDeviceSubjectAreaHasChanged:(NSNotification* )notification {
    //NSLog(@"captureDeviceSubjectAreaHasChanged: %@", notification);
    AVCaptureDevice* cameraDevice = self.videoDeviceInput.device;
    if (cameraDevice.exposureMode == AVCaptureExposureModeLocked
        && [cameraDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]
        && [cameraDevice lockForConfiguration:Nil] )
    {
        cameraDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        [cameraDevice unlockForConfiguration];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == CAMERA_ZOOM_CONTEXT) {
        if ([self.delegate respondsToSelector:@selector(captureController:DidCameraZoomToFactor:)]) {
            [self.delegate captureController:self
                       DidCameraZoomToFactor:self.cameraZoomFactor];
        }
    }
}

//
// MARK: - session configuration
//
- (void)setupSessionWithCompletionHandle:(void(^)(void))completionHandler {
    // check video device authorized state
    AVAuthorizationStatus videoAuthorizedStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    AVAuthorizationStatus audioAuthorizedStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (videoAuthorizedStatus == AVAuthorizationStatusDenied || audioAuthorizedStatus == AVAuthorizationStatusDenied) {
        if ([self.delegate respondsToSelector:@selector(captureController:ConfigureSessionResult:Error:)])
            [self.delegate captureController:self ConfigureSessionResult:SessionConfigResultUnAuthorized Error:nil];
        return;
    }
    
    if (videoAuthorizedStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                                 completionHandler:^(BOOL granted) {
                                     if (!granted) {
                                         if ([self.delegate respondsToSelector:@selector(captureController:ConfigureSessionResult:Error:)])
                                             [self.delegate captureController:self ConfigureSessionResult:SessionConfigResultUnAuthorized Error:nil];
                                     } else {
                                         if (audioAuthorizedStatus == AVAuthorizationStatusNotDetermined) {
                                             [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                                                 if (!granted) {
                                                     if ([self.delegate respondsToSelector:@selector(captureController:ConfigureSessionResult:Error:)])
                                                         [self.delegate captureController:self ConfigureSessionResult:SessionConfigResultUnAuthorized Error:nil];
                                                 } else {
                                                     [self doSetupSessionWithCompletionHandle:completionHandler];
                                                 }
                                             }];
                                         } else {
                                             [self doSetupSessionWithCompletionHandle:completionHandler];
                                         }
                                     }
                                 }];
        return;
    }
    
    if (audioAuthorizedStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            if (!granted) {
                if ([self.delegate respondsToSelector:@selector(captureController:ConfigureSessionResult:Error:)])
                    [self.delegate captureController:self ConfigureSessionResult:SessionConfigResultUnAuthorized Error:nil];
            } else {
                [self doSetupSessionWithCompletionHandle:completionHandler];
            }
        }];
        return;
    }

    // we already got video/audio devices access authorization
    // setup session in session queue
    [self doSetupSessionWithCompletionHandle:completionHandler];

}

- (void)doSetupSessionWithCompletionHandle:(void(^)(void))completionHandler {
    dispatch_async(self.sessionQueue, ^{
        NSArray* devicesType = @[AVCaptureDeviceTypeBuiltInDualCamera,
                                 AVCaptureDeviceTypeBuiltInWideAngleCamera,
                                 AVCaptureDeviceTypeBuiltInTrueDepthCamera];
        self.discoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:devicesType
                                                                                       mediaType:AVMediaTypeVideo
                                                                                        position:AVCaptureDevicePositionUnspecified];
        if (SESSION_DEBUG_INFO) {
            NSLog(@"[CaptureController debug info] discovery devices: %@", self.discoverySession.devices);
        }
        
        [self.session beginConfiguration];
        self.session.sessionPreset = AVCaptureSessionPresetPhoto;
        
        NSError* e;
        // add audio input
        AVCaptureDevice* audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        self.audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&e];
        if (!self.audioDeviceInput) {
            if ([self.delegate respondsToSelector:@selector(captureController:ConfigureSessionResult:Error:)])
                [self.delegate captureController:self ConfigureSessionResult:SessionConfigResultFailed Error:e];
            [self.session commitConfiguration];
            return;
        }
        if ([self.session canAddInput:self.audioDeviceInput]) {
            [self.session addInput:self.audioDeviceInput];
            if (SESSION_DEBUG_INFO) {
                NSLog(@"[CaptureController debug info] session add audio devices input: %@", audioDevice);
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(captureController:ConfigureSessionResult:Error:)])
                [self.delegate captureController:self ConfigureSessionResult:SessionConfigResultFailed Error:nil];
            [self.session commitConfiguration];
            return;
        }
        
        // add video input
        for (AVCaptureDevice* device in self.discoverySession.devices) {
            self.videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device
                                                                          error:&e];
            if (self.videoDeviceInput)
                break;
        }
        
        if (!self.videoDeviceInput) {
            AVCaptureDevice* videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            self.videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&e];
            if (!self.videoDeviceInput) {
                if ([self.delegate respondsToSelector:@selector(captureController:ConfigureSessionResult:Error:)])
                    [self.delegate captureController:self ConfigureSessionResult:SessionConfigResultFailed Error:e];
                [self.session commitConfiguration];
                return;
            }
        }
        
        if([self.session canAddInput:self.videoDeviceInput]) {
            [self.session addInput:self.videoDeviceInput];
            if ([self.videoDeviceInput.device lockForConfiguration:Nil]) {
                self.videoDeviceInput.device.subjectAreaChangeMonitoringEnabled = TRUE;
                [self.videoDeviceInput.device unlockForConfiguration];
            }
            [self addVideoDeviceObserver];
            
            if (SESSION_DEBUG_INFO) {
                NSLog(@"[CaptureController debug info] seesion add video devices input: %@", self.videoDeviceInput.device);
            }
        }else {
            if ([self.delegate respondsToSelector:@selector(captureController:ConfigureSessionResult:Error:)])
                [self.delegate captureController:self ConfigureSessionResult:SessionConfigResultFailed Error:nil];
            [self.session commitConfiguration];
            return;
        }
        

        // add photo output
        self.photoOutput = [AVCapturePhotoOutput new];
        self.photoOutput.livePhotoCaptureEnabled = self.photoOutput.livePhotoCaptureSupported;
        self.photoOutput.highResolutionCaptureEnabled = TRUE;
    
        if ([self.session canAddOutput:self.photoOutput]) {
            [self.session addOutput:self.photoOutput];
            if (SESSION_DEBUG_INFO) {
                NSLog(@"[CaptureController debug info] session add output: %@", self.photoOutput);
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(captureController:ConfigureSessionResult:Error:)])
                [self.delegate captureController:self ConfigureSessionResult:SessionConfigResultFailed Error:nil];
            [self.session commitConfiguration];
            return;
        }
        self.flashMode = AVCaptureFlashModeOff;
        if ([[self.photoOutput supportedFlashModes] containsObject:[NSNumber numberWithInt:AVCaptureFlashModeAuto]]) {
            self.flashMode = AVCaptureFlashModeAuto;
        }
        
        // movie file output
        self.movieOutput = [AVCaptureMovieFileOutput new];
        self.movieOutput.movieFragmentInterval = CMTimeMakeWithSeconds(5, NSEC_PER_SEC);
        
        [self.session commitConfiguration];
        [self startSession];
        
        // enable all avaliable device capbilities at default
        self.tapToFocusEnabled = self.tapToFocusSupported;
        self.tapToExposureEnabled = self.tapToExposureSupported;
        self.switchCameraEnabled = self.switchCameraSupported;
        self.cameraZoomEnabled = self.cameraZoomSupported;
        
        if (completionHandler) {
            completionHandler();
        }
    });
}

- (void)setPreviewLayer:(AVCaptureVideoPreviewLayer*)videoPreviewlayer {
    videoPreviewlayer.session = self.session;
    self.videoPreviewLayer = videoPreviewlayer;
}

- (void)startSession {
    //startRunning method is a blocking call which can take some time
    if (!self.session.running) {
        dispatch_async(self.sessionQueue, ^{
            [self.session startRunning];
        });
    }
}

- (void)stopSession {
    if (self.session.running) {
        [self.session stopRunning];
    }
}

- (void)cleanUpSession {
    [self stopSession];
    [self removeVideoDeviceObserver];
    [self removeSessionObserver];
}

- (void)addSessionObserver {
    NSNotificationCenter* defaultNC = [NSNotificationCenter defaultCenter];
    [defaultNC addObserver:self
                  selector:@selector(sessionRuntimeErrorNotification:)
                      name:AVCaptureSessionRuntimeErrorNotification
                    object:self.session];
    [defaultNC addObserver:self
                  selector:@selector(sessionStartRunningNotification:)
                      name:AVCaptureSessionDidStartRunningNotification
                    object:self.session];
    [defaultNC addObserver:self
                  selector:@selector(sessionStopRunningNotification:)
                      name:AVCaptureSessionDidStopRunningNotification
                    object:self.session];
    [defaultNC addObserver:self
                  selector:@selector(sessionWasInteruptNotification:)
                      name:AVCaptureSessionWasInterruptedNotification
                    object:self.session];
}

- (void)addVideoDeviceObserver {
    NSNotificationCenter* defaultNC = [NSNotificationCenter defaultCenter];
    [defaultNC addObserver:self
                  selector:@selector(captureDeviceSubjectAreaHasChanged:)
                      name:AVCaptureDeviceSubjectAreaDidChangeNotification
                    object:self.videoDeviceInput.device];
    
    [self.videoDeviceInput.device addObserver:self
                                   forKeyPath:@"videoZoomFactor"
                                      options:NSKeyValueObservingOptionNew
                                      context:CAMERA_ZOOM_CONTEXT];
}

- (void)removeSessionObserver {
    NSNotificationCenter* defaultNC = [NSNotificationCenter defaultCenter];
    @try {
        //        [defaultNC removeObserver:self name:AVCaptureSessionRuntimeErrorNotification object:self.session];
        //        [defaultNC removeObserver:self name:AVCaptureSessionDidStartRunningNotification object:self.session];
        //        [defaultNC removeObserver:self name:AVCaptureSessionDidStopRunningNotification object:self.session];
        [defaultNC removeObserver:self];
        [self.videoDeviceInput.device removeObserver:self
                                          forKeyPath:@"videoZoomFactor"
                                             context:CAMERA_ZOOM_CONTEXT];
    } @catch (NSException *exception) {
        //do nothing
    }
}

- (void)removeVideoDeviceObserver {
    NSNotificationCenter* defaultNC = [NSNotificationCenter defaultCenter];
    @try {
        [defaultNC removeObserver:self.videoDeviceInput.device];
    } @catch (NSException *exception) {
        // do nothing
    }
}

//
// MARK: - switch capture mode
//
- (void)switchToMode:(CaptureMode)mode {
    dispatch_async(self.sessionQueue, ^{
        BOOL success = [self configSessionForMode:mode];
        if (success) {
            [self enumerateDeviceForMode:mode];
            //[self startSession];
            self.currentCaptureMode = mode;
            if ([self.delegate respondsToSelector:@selector(captureController:EnterCaptureMode:)]) {
                [self.delegate captureController:self
                                EnterCaptureMode:mode];
            }
        }
    });
}

- (BOOL)configSessionForMode:(CaptureMode)mode {
    if (mode == self.currentCaptureMode) {
        return TRUE;
    }
    
    if ([self.delegate respondsToSelector:@selector(captureController:LeaveCaptureMode:)]) {
        [self.delegate captureController:self
                        LeaveCaptureMode:self.currentCaptureMode];
    }
    

    if (mode == CaptureModePhoto) {
        [self.session beginConfiguration];
        self.session.sessionPreset = AVCaptureSessionPresetPhoto;
        // remove movieFileOutput object if any
        // captureSession can not support both live photo capture and movie file output
        if (self.movieOutput) {
            [self.session removeOutput:self.movieOutput];
            if (SESSION_DEBUG_INFO) {
                NSLog(@"[CaptureController debug info] remove output: %@", self.movieOutput);
            }
            //self.movieOutput = nil;
        }
        
        AVCaptureConnection* photoOutputConnection = [self.photoOutput connectionWithMediaType:AVMediaTypeVideo];
        photoOutputConnection.enabled = TRUE;
        
        [self.session commitConfiguration];
    }
    
    
    
    else if (mode == CaptureModeVideo) {
        [self.session beginConfiguration];
        self.session.sessionPreset = AVCaptureSessionPresetHigh;
        if (!self.movieOutput) {
            self.movieOutput = [AVCaptureMovieFileOutput new];
        }
        if ([self.session canAddOutput:self.movieOutput]) {
            [self.session addOutput:self.movieOutput];
            if (SESSION_DEBUG_INFO) {
                NSLog(@"[CaptureController debug info] session add output: %@", self.movieOutput);
            }
        } else {
            [self.session commitConfiguration];
            return FALSE;
        }
        if (self.photoOutput) {
            AVCaptureConnection* photoOutputConnection = [self.photoOutput connectionWithMediaType:AVMediaTypeVideo];
            photoOutputConnection.enabled = FALSE;
        }
        [self.session commitConfiguration];
    }
    
    return TRUE;
}

- (void)enumerateDeviceForMode:(CaptureMode)mode {
    if (mode == CaptureModePhoto) {
        
        
    } else if (mode == CaptureModeVideo) {
        
        
    }
}


//
// MARK: - device capability
//
- (BOOL)tapToFocusSupported {
    AVCaptureDevice* cameraDevice = self.videoDeviceInput.device;
    return [cameraDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] && [cameraDevice isFocusPointOfInterestSupported];
}

- (BOOL)tapToExposureSupported {
    AVCaptureDevice* cameraDevice = self.videoDeviceInput.device;
    return [cameraDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose] && [cameraDevice isExposurePointOfInterestSupported];
}

- (void)tapToFocusAtInterestPoint:(CGPoint)point {
    dispatch_async(self.sessionQueue, ^{
        if (self.tapToFocusSupported && self.tapToFocusEnabled) {
            AVCaptureDevice* cameraDevice = self.videoDeviceInput.device;
            NSError* e = nil;
            if(![cameraDevice lockForConfiguration:&e]) {
                if ([self.delegate respondsToSelector:@selector(captureController:ConfigureDevice:FailedWithError:)]) {
                    [self.delegate captureController:self
                                     ConfigureDevice:cameraDevice
                                     FailedWithError:e];
                }
                
                if (SESSION_DEBUG_INFO) {
                    NSLog(@"[CaptureController debug info] tapToFocusAtInterestPoint failed with error: %@", e);
                }
                return ;
            }
            
            cameraDevice.focusMode = AVCaptureFocusModeAutoFocus;
            cameraDevice.focusPointOfInterest = point;
            [cameraDevice unlockForConfiguration];
        }
    });
}

- (void)tapToExposureAtInterestPoint:(CGPoint)point {
    dispatch_async(self.sessionQueue, ^{
        if (self.tapToExposureSupported && self.tapToExposureEnabled) {
            AVCaptureDevice* cameraDevice = self.videoDeviceInput.device;
            NSError* e = nil;
            if (![cameraDevice lockForConfiguration:&e]) {
                if ([self.delegate respondsToSelector:@selector(captureController:ConfigureDevice:FailedWithError:)]) {
                    [self.delegate captureController:self
                                     ConfigureDevice:cameraDevice
                                     FailedWithError:e];
                }
                
                if (SESSION_DEBUG_INFO) {
                    NSLog(@"[CaptureController debug info] tapToFocusAtInterestPoint failed with error: %@", e);
                }
                return ;
            }
            
            cameraDevice.exposureMode = AVCaptureExposureModeAutoExpose;
            cameraDevice.exposurePointOfInterest = point;
            [cameraDevice unlockForConfiguration];
        }
    });
}

- (void)resetFocus {
    AVCaptureDevice* cameraDevice = self.videoDeviceInput.device;
    if ([cameraDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]){
        NSError* e = nil;
        if (![cameraDevice lockForConfiguration:&e]) {
            if ([self.delegate respondsToSelector:@selector(captureController:ConfigureDevice:FailedWithError:)]) {
                [self.delegate captureController:self
                                 ConfigureDevice:cameraDevice
                                 FailedWithError:e];
            }
            
            if (SESSION_DEBUG_INFO) {
                NSLog(@"[CaptureController debug info] resetFocus failed with error: %@", e);
            }
            return ;
        }
        cameraDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        [cameraDevice unlockForConfiguration];
    }
}

- (void)resetExposure {
    AVCaptureDevice* cameraDevice = self.videoDeviceInput.device;
    if ([cameraDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]){
        NSError* e = nil;
        if (![cameraDevice lockForConfiguration:&e]) {
            if ([self.delegate respondsToSelector:@selector(captureController:ConfigureDevice:FailedWithError:)]) {
                [self.delegate captureController:self
                                 ConfigureDevice:cameraDevice
                                 FailedWithError:e];
            }
            
            if (SESSION_DEBUG_INFO) {
                NSLog(@"[CaptureController debug info] resetExposure failed with error: %@", e);
            }
            return ;
        }
        
        cameraDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        [cameraDevice unlockForConfiguration];
    }
}

- (BOOL)switchCameraSupported {
    return self.discoverySession.devices.count > 1;
}

- (void)switchCamera {
    if (self.switchCameraSupported && self.switchCameraEnabled) {
        AVCaptureDevice* currentDevice = self.videoDeviceInput.device;
        AVCaptureDevice* targetDevice = Nil;
        
        for (AVCaptureDevice* device in self.discoverySession.devices) {
            if (device != currentDevice && device.position != currentDevice.position)
            {
                targetDevice = device;
                break;
            }
        }
        
        if (targetDevice) {
            NSError* e;
            AVCaptureDeviceInput* targetDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:targetDevice
                                                                                            error:&e];
            if (!targetDeviceInput) {
                if ([self.delegate respondsToSelector:@selector(captureController:ConfigureSessionResult:Error:)]) {
                    [self.delegate captureController:self
                              ConfigureSessionResult:SessionConfigResultFailed
                                               Error:e];
                }
                return ;
            }
            
            dispatch_async(self.sessionQueue, ^{
                BOOL success = FALSE;
                AVCaptureDeviceInput* currentDeviceInput = self.videoDeviceInput;
                [self.session beginConfiguration];
                [self removeVideoDeviceObserver];
                [self.session removeInput:self.videoDeviceInput];
                if ([self.delegate respondsToSelector:@selector(captureControllerBeginSwitchCamera)]) {
                    [self.delegate captureControllerBeginSwitchCamera];
                }

                if([self.session canAddInput:targetDeviceInput]) {
                    [self.session addInput:targetDeviceInput];
                    self.videoDeviceInput = targetDeviceInput;
                    if ([self.videoDeviceInput.device lockForConfiguration:Nil]) {
                        self.videoDeviceInput.device.subjectAreaChangeMonitoringEnabled = TRUE;
                        [self.videoDeviceInput.device unlockForConfiguration];
                    }
                    [self enumerateDeviceForMode:self.currentCaptureMode];
                    success = TRUE;
                } else {
                    [self.session addInput:currentDeviceInput];
                }
                [self addVideoDeviceObserver];
                [self.session commitConfiguration];
                
                if ([self.delegate respondsToSelector:@selector(captureControllerDidFinishSwitchCamera:)]) {
                    [self.delegate captureControllerDidFinishSwitchCamera:success];
                }
            });
        }
    }
}

- (BOOL)cameraZoomSupported {
    //return self.videoDeviceInput.device.activeFormat.videoMaxZoomFactor > 1;
    return self.cameraMaxZoomFactor > 1;
}

- (CGFloat)cameraMinZoomFactor {
    return self.videoDeviceInput.device.minAvailableVideoZoomFactor;
}

- (CGFloat)cameraMaxZoomFactor {
    CGFloat maxZoomFactor = MAX(self.videoDeviceInput.device.minAvailableVideoZoomFactor, self.videoDeviceInput.device.maxAvailableVideoZoomFactor);
    maxZoomFactor = MIN(maxZoomFactor, 4);
    return maxZoomFactor;
}

- (CGFloat)cameraZoomFactor {
    return self.videoDeviceInput.device.videoZoomFactor;
}

- (void)setVideoZoomWithFactor:(CGFloat)factor {
    dispatch_async(self.sessionQueue, ^{
        if (self.cameraZoomSupported && self.cameraZoomEnabled) {
            CGFloat clampFactor = MIN(self.cameraMaxZoomFactor, factor);
            clampFactor = MAX(self.cameraMinZoomFactor, clampFactor);
            AVCaptureDevice* cameraDevice = self.videoDeviceInput.device;
            NSError* e;
            if (!cameraDevice.isRampingVideoZoom) {
                if (![cameraDevice lockForConfiguration:&e]) {
                    if ([self.delegate respondsToSelector:@selector(captureController:ConfigureDevice:FailedWithError:)]) {
                        [self.delegate captureController:self
                                         ConfigureDevice:cameraDevice
                                         FailedWithError:e];
                    }
                    if (SESSION_DEBUG_INFO) {
                        NSLog(@"[CaptureController debug info] set video zoom factor failed with error: %@", e);
                    }
                    return ;
                }
                cameraDevice.videoZoomFactor = clampFactor;
                [cameraDevice unlockForConfiguration];
            }
        }
    });
}

- (void)setVideoZoomWithPercent:(float)percent {
    float clampPercent = MIN(percent, 1);
    clampPercent = MAX(clampPercent, 0);
    //float factor = self.cameraMinZoomFactor + (self.cameraMaxZoomFactor - self.cameraMinZoomFactor) * percent;
    float factor = MAX(powf(self.cameraMaxZoomFactor, percent) , self.cameraMinZoomFactor);
    [self setVideoZoomWithFactor:factor];
}

- (void)smoothZoomVideoTo:(CGFloat)zoomFactor WithRate:(float)rate {
    dispatch_async(self.sessionQueue, ^{
        if (self.cameraZoomSupported && self.cameraZoomEnabled) {
            CGFloat clampFactor = MIN(self.cameraMaxZoomFactor, zoomFactor);
            clampFactor = MAX(self.cameraMinZoomFactor, clampFactor);
            AVCaptureDevice* cameraDevice = self.videoDeviceInput.device;
            NSError* e;
            if (![cameraDevice lockForConfiguration:&e]) {
                if ([self.delegate respondsToSelector:@selector(captureController:ConfigureDevice:FailedWithError:)]) {
                    [self.delegate captureController:self
                                     ConfigureDevice:cameraDevice
                                     FailedWithError:e];
                }
                if (SESSION_DEBUG_INFO) {
                    NSLog(@"[CaptureController debug info] ramping video zoom factor failed with error: %@", e);
                }
                return ;
            }
            
            [cameraDevice rampToVideoZoomFactor:clampFactor withRate:rate];
            [cameraDevice unlockForConfiguration];
        }
    });
}

- (void)cancelVideoSmoothZoom {
    dispatch_async(self.sessionQueue, ^{
        if (self.cameraZoomSupported && self.cameraZoomEnabled) {
            AVCaptureDevice* cameraDevice = self.videoDeviceInput.device;
            NSError* e;
            if (![cameraDevice lockForConfiguration:&e]) {
                if ([self.delegate respondsToSelector:@selector(captureController:ConfigureDevice:FailedWithError:)]) {
                    [self.delegate captureController:self
                                     ConfigureDevice:cameraDevice
                                     FailedWithError:e];
                }
                if (SESSION_DEBUG_INFO) {
                    NSLog(@"[CaptureController debug info] cancel ramping video zoom factor failed with error: %@", e);
                }
                return ;
            }
            [cameraDevice cancelVideoZoomRamp];
            [cameraDevice unlockForConfiguration];
        }
    });
}

- (BOOL)flashModeSwitchSupported {
    AVCaptureDevice* cameraDevice = self.videoDeviceInput.device;
    return cameraDevice.flashAvailable && self.photoOutput.supportedFlashModes.count > 1;
}

- (void)switchFlashMoe:(AVCaptureFlashMode)mode {
    dispatch_async(self.sessionQueue, ^{
        if (self.flashMode == mode){
            return ;
        }
        
        if (self.flashModeSwitchSupported && self.flashModeSwitchEnabled) {
            if ([self.delegate respondsToSelector:@selector(captureController:WillSwitchFlashModeFrom:)]) {
                [self.delegate captureController:self
                         WillSwitchFlashModeFrom:self.flashMode];
            }
        }
        
        if ([self.photoOutput.supportedFlashModes containsObject:[NSNumber numberWithInt:mode]]) {
            self.flashMode = mode;
            if ([self.delegate respondsToSelector:@selector(captureController:DidSwitchFlashModeTo:)]) {
                [self.delegate captureController:self
                            DidSwitchFlashModeTo:self.flashMode];
            }
        }
    });
}


//
// MARK: - capture photo/video
//
- (void)capturePhoto {
    dispatch_async(self.sessionQueue, ^{
        if (self.currentCaptureMode != CaptureModePhoto) {
            if ([self.delegate respondsToSelector:@selector(captureController:InavailbleCaptureRequestForMode:)]) {
                [self.delegate captureController:self
                 InavailbleCaptureRequestForMode:self.currentCaptureMode];
            }
            return;
        }
        
        AVCaptureConnection* photoOutputVideoConnection = [self.photoOutput connectionWithMediaType:AVMediaTypeVideo];
        if (photoOutputVideoConnection.supportsVideoOrientation) {
            //photoOutputVideoConnection.videoOrientation = self.videoPreviewLayer.connection.videoOrientation;
            photoOutputVideoConnection.videoOrientation = [self currentVideoOrientationWithCureentDevice];
        }
        if (photoOutputVideoConnection.supportsVideoStabilization) {
            photoOutputVideoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
        
        AVCaptureDevice* cameraDevice = self.videoDeviceInput.device;
        if (cameraDevice.smoothAutoFocusSupported) {
            if ([cameraDevice lockForConfiguration:nil]) {
                cameraDevice.smoothAutoFocusEnabled = FALSE;
                [cameraDevice unlockForConfiguration];
            }
        }
        
        AVCapturePhotoSettings* captureSetting = nil;
        if ([self.photoOutput.availablePhotoCodecTypes containsObject:AVVideoCodecTypeHEVC] ) {
            captureSetting = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey:AVVideoCodecTypeHEVC}];
        } else {
            captureSetting = [AVCapturePhotoSettings photoSettings];
        }
        captureSetting.highResolutionPhotoEnabled  = self.photoOutput.highResolutionCaptureEnabled;
        captureSetting.autoStillImageStabilizationEnabled = self.photoOutput.stillImageStabilizationSupported;
        self.photoOutput.livePhotoCaptureEnabled = FALSE;
        captureSetting.flashMode = AVCaptureFlashModeOff;
        if (self.flashModeSwitchSupported && self.flashModeSwitchEnabled) {
            captureSetting.flashMode = self.flashMode;
        }
        
        [self.photoCaptureSettingsOnProgressing setObject:captureSetting forKey:[NSNumber numberWithLongLong:captureSetting.uniqueID]];
        [self.photoOutput capturePhotoWithSettings:captureSetting
                                          delegate:self];
    });
}

- (void)startRecording {
    dispatch_async(self.sessionQueue, ^{
        if (self.recording)
            return ;
        
        if (self.currentCaptureMode != CaptureModeVideo) {
            if ([self.delegate respondsToSelector:@selector(captureController:InavailbleCaptureRequestForMode:)]) {
                [self.delegate captureController:self
                 InavailbleCaptureRequestForMode:CaptureModeVideo];
            }
            return;
        }
        
         AVCaptureConnection* movieOutputVideoConnection = [self.movieOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([self.movieOutput.availableVideoCodecTypes containsObject:AVVideoCodecTypeHEVC]) {
            [self.movieOutput setOutputSettings:@{AVVideoCodecKey:AVVideoCodecTypeHEVC}
                                  forConnection:movieOutputVideoConnection];
        }
        
        if (movieOutputVideoConnection.supportsVideoOrientation) {
            //movieOutputVideoConnection.videoOrientation = self.videoPreviewLayer.connection.videoOrientation;
            movieOutputVideoConnection.videoOrientation = [self currentVideoOrientationWithCureentDevice];
        }
        if (movieOutputVideoConnection.supportsVideoStabilization) {
            movieOutputVideoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
        
        AVCaptureDevice* cameraDevice = self.videoDeviceInput.device;
        if (cameraDevice.smoothAutoFocusSupported) {
            if ([cameraDevice lockForConfiguration:nil]) {
                cameraDevice.smoothAutoFocusEnabled = TRUE;
                [cameraDevice unlockForConfiguration];
            }
        }
    
        NSURL* url = [self uniqueResourceURLAtDirectory:NSTemporaryDirectory() WithFileExtension:@"mov"];
        [self.movieOutput startRecordingToOutputFileURL:url
                                      recordingDelegate:self];
    });
}

- (void)stopRecording {
    dispatch_async(self.sessionQueue, ^{
        if (self.recording) {
            [self.movieOutput stopRecording];
        }
    });
}

- (BOOL)recording {
    return self.movieOutput.recording;
}

- (AVCaptureVideoOrientation)currentVideoOrientationWithCureentDevice {
    UIDevice* currentDevice = [UIDevice currentDevice];
    AVCaptureVideoOrientation videoOrientation = AVCaptureVideoOrientationPortrait;
    switch (currentDevice.orientation) {
        case UIDeviceOrientationPortrait:
            videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeLeft:
            videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        default:
            break;
    }
    
    return videoOrientation;
}

- (NSURL*)uniqueResourceURLAtDirectory:(NSString*)directory WithFileExtension:(NSString*)ext {
    NSString* uniqueFileName = [NSString stringWithFormat:@"%@.%@", [NSUUID new].UUIDString, ext];
    NSString* urlPathString = [directory stringByAppendingPathComponent:uniqueFileName];
    return [NSURL fileURLWithPath:urlPathString];
}

- (void)requestPhotoLibraryAccessAuthorizationWithCompletionHandler:(void(^)(BOOL))completionHandler {
    PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
    if (authorizationStatus == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            completionHandler(status == PHAuthorizationStatusAuthorized);
        }];
        return;
    }
    completionHandler(authorizationStatus == PHAuthorizationStatusAuthorized);
}

- (void)savePhotoToPhotoLibraryWithCaptureUUID:(int64_t)uuid {
    dispatch_async(self.sessionQueue, ^{
        NSNumber* key = [NSNumber numberWithLongLong:uuid];
        AVCapturePhotoSettings* captureSetting = [self.photoCaptureSettingsOnProgressing objectForKey:key];
        NSData* photoData = [self.photoCaptureDataOnProgressing objectForKey:key];
        
        [self requestPhotoLibraryAccessAuthorizationWithCompletionHandler:^(BOOL grant) {
            if (!grant) {
                if ([self.delegate respondsToSelector:@selector(captureController:SavePhoto:ToLibraryWithResult:Error:)]){
                    [self.delegate captureController:self
                                           SavePhoto:photoData
                                 ToLibraryWithResult:AssetSavedResultUnAuthorized
                                               Error:nil];
                }
            } else {
                if (SESSION_DEBUG_INFO) {
                    NSLog(@"[CaptureController debug info] saving photo data at address: %d for key: %@", (int)photoData.bytes, key);
                }
                
                [[PHPhotoLibrary sharedPhotoLibrary]performChanges:^{
                    PHAssetResourceCreationOptions* options = [PHAssetResourceCreationOptions new];
                    options.uniformTypeIdentifier = captureSetting.processedFileType;
                    PHAssetCreationRequest* newAssetRequest = [PHAssetCreationRequest creationRequestForAsset];
                    
                    [newAssetRequest addResourceWithType:PHAssetResourceTypePhoto
                                                    data:photoData
                                                 options:options];
                } completionHandler:^(BOOL success, NSError * _Nullable error) {
                    if (SESSION_DEBUG_INFO) {
                        NSLog(@"[CaptureController debug info] saving photo data at address: %d for key: %@, success: %d", (int)photoData.bytes, key, success);
                    }
                    if (success) {
                        [self.photoCaptureSettingsOnProgressing removeObjectForKey:key];
                        [self.photoCaptureDataOnProgressing removeObjectForKey:key];
                    }
                    AssetSavedResult reslut = success ? AssetSavedResultSuccess : AssetSavedResultFailed;
                    if ([self.delegate respondsToSelector:@selector(captureController:SavePhoto:ToLibraryWithResult:Error:)]) {
                        [self.delegate captureController:self
                                               SavePhoto:photoData
                                     ToLibraryWithResult:reslut
                                                   Error:error];
                    }
                }];
            }
        }];
    });
}

- (void)saveVideoToPhotoLibararyWithURL:(NSURL*)url {
    [self requestPhotoLibraryAccessAuthorizationWithCompletionHandler:^(BOOL grant) {
        if (!grant) {
            if ([self.delegate respondsToSelector:@selector(captureController:SaveVideo:ToLibraryWithResult:Error:)]) {
                [self.delegate captureController:self
                                       SaveVideo:url
                             ToLibraryWithResult:AssetSavedResultUnAuthorized
                                           Error:nil];
            }
        } else {
            dispatch_async(self.sessionQueue, ^{
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    PHAssetResourceCreationOptions* options = [PHAssetResourceCreationOptions new];
                    options.shouldMoveFile = TRUE;
                    PHAssetCreationRequest* saveVideoRequest = [PHAssetCreationRequest creationRequestForAsset];
                    [saveVideoRequest addResourceWithType:PHAssetResourceTypeVideo
                                                  fileURL:url
                                                  options:options];
                } completionHandler:^(BOOL success, NSError * _Nullable error) {
                    if ([self.delegate respondsToSelector:@selector(captureController:SaveVideo:ToLibraryWithResult:Error:)]) {
                        AssetSavedResult result = success ? AssetSavedResultSuccess : AssetSavedResultFailed;
                        [self.delegate captureController:self
                                               SaveVideo:url
                                     ToLibraryWithResult:result
                                                   Error:error];
                    }
                    if (!success) {
                        NSFileManager* fileManager = [NSFileManager defaultManager];
                        if ([fileManager fileExistsAtPath:url.path]) {
                            [fileManager removeItemAtPath:url.path
                                                    error:nil];
                        }
                    }
                    if (SESSION_DEBUG_INFO) {
                        NSLog(@"[CaptureController debug info] saving video at: %@, success: %d", url, success);
                    }
                }];
            });
        }
    }];
}

//
// MARK: - controller delegate
//
- (void)sessionRuntimeErrorNotification:(NSNotification*)notification {
    if ([self.delegate respondsToSelector:@selector(captureControllerSessionRuntimeError:)]) {
        [self.delegate captureControllerSessionRuntimeError:self];
    }
}

- (void)sessionStartRunningNotification:(NSNotification*)notification {
    if ([self.delegate respondsToSelector:@selector(captureControllerSessionDidStartRunning:)]) {
        [self.delegate captureControllerSessionDidStartRunning:self];
    }
}

- (void)sessionStopRunningNotification:(NSNotification*)notification {
    if ([self.delegate respondsToSelector:@selector(captureControllerSessionDidStopRunning:)]) {
        [self.delegate captureControllerSessionDidStopRunning:self];
    }
}

- (void)sessionWasInteruptNotification:(NSNotification*)notification {
    NSLog(@"session was intterupt: %@", notification);
}

//
// MARK: - photo / video capture delegate
//
- (void)captureOutput:(AVCapturePhotoOutput *)output willCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    if ([self.delegate respondsToSelector:@selector(captureController:WillCapturePhotoWithSettings:)]) {
        [self.delegate captureController:self
            WillCapturePhotoWithSettings:resolvedSettings];
    }
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    if([self.delegate respondsToSelector:@selector(captureController:DidCapturePhotoWithSettings:)]) {
        [self.delegate captureController:self
             DidCapturePhotoWithSettings:resolvedSettings];
    }
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
    dispatch_async(self.sessionQueue, ^{
        NSNumber* key = [NSNumber numberWithLongLong:photo.resolvedSettings.uniqueID];
        NSData* photoData = [photo fileDataRepresentation];
        [self.photoCaptureDataOnProgressing setObject:photoData forKey:key];
        if (SESSION_DEBUG_INFO) {
            NSLog(@"[CaptureController debug info] Generating photo data at address:%d, for key: %@ success", (int)photoData.bytes, key);
        }
    });
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(NSError *)error {
    if([self.delegate respondsToSelector:@selector(captureController:DidFinishCapturePhotoWithSettings:Error:)]) {
        [self.delegate captureController:self
       DidFinishCapturePhotoWithSettings:resolvedSettings
                                   Error:error];
    }
    
    if (!error) {
        [self savePhotoToPhotoLibraryWithCaptureUUID:resolvedSettings.uniqueID];
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections {
    if ([self.delegate respondsToSelector:@selector(captureController:DidStartRecordingToFileURL:)]) {
        [self.delegate captureController:self
              DidStartRecordingToFileURL:fileURL];
    }
    if (SESSION_DEBUG_INFO) {
        NSLog(@"[CaptureController debug info] start recording at url: %@", fileURL);
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(captureController:DidFinishRecordingToFileURL:Error:)]) {
        [self.delegate captureController:self
             DidFinishRecordingToFileURL:outputFileURL
                                   Error:error];
    }
    
    if (SESSION_DEBUG_INFO) {
        NSLog(@"[CaptureController debug info] finish recording at url: %@, error: %@", outputFileURL, error);
    }
    
    dispatch_async(self.sessionQueue, ^{
        [self saveVideoToPhotoLibararyWithURL:outputFileURL];
    });
}




@end

