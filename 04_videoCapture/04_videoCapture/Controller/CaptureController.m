//
//  SYCaptureController.m
//  04_videoCapture
//
//  Created by sy on 2019/7/9.
//  Copyright © 2019 sy. All rights reserved.
//

#import "CaptureController.h"


@interface CaptureController ()

@property (strong, nonatomic) AVCaptureSession* session;
@property (strong, nonatomic) AVCaptureDeviceDiscoverySession* discoverySession;
//@property (strong, nonatomic) AVCaptureDevice* videoDevice;
@property (strong, nonatomic) AVCaptureDeviceInput* videoDeviceInput;
//@property (strong, nonatomic) AVCaptureDevice* audioDevice;
@property (strong, nonatomic) AVCaptureDeviceInput* audioDeviceInput;
//@property (strong, nonatomic) AVCaptureDeviceInput* activeDeviceInput;
@property (strong, nonatomic) AVCaptureMovieFileOutput* movieOutput;
@property (strong, nonatomic) AVCapturePhotoOutput* photoOutput;
@property (nonatomic) CaptureMode currentCaptureMode;

@end


@implementation CaptureController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.currentCaptureMode = CaptureModeUnkonwed;
    }
    return self;
}


//
// MARK: - session configuration
//
- (SessionSetupResult)setupSession {
    NSArray* devicesType = @[AVCaptureDeviceTypeBuiltInDualCamera, AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInTrueDepthCamera];
    self.discoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:devicesType
                                                                                   mediaType:AVMediaTypeVideo
                                                                                    position:AVCaptureDevicePositionUnspecified];
    if (SESSION_DEBUG_INFO) {
        NSLog(@"[CaptureController debug info] discovery devices: %@", self.discoverySession.devices);
    }
    
    self.session = [AVCaptureSession new];
    [self addSessionObserver];
    [self.session beginConfiguration];
    self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    
    NSError* e;
    // add audio input
    AVCaptureDevice* audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    self.audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&e];
    if (!self.audioDeviceInput) {
        if ([self.delegate respondsToSelector:@selector(captureController:ConfigureSessionFailedWithError:)]) {
            [self.delegate captureController:nil ConfigureSessionFailedWithError:e];
        }
        return SessionSetupResultFailed;
    }
    if ([self.session canAddInput:self.audioDeviceInput]) {
        [self.session addInput:self.audioDeviceInput];
        if (SESSION_DEBUG_INFO) {
            NSLog(@"[CaptureController debug info] session add audio devices input: %@", audioDevice);
        }
    }
    
    // add video input
    AVCaptureDevice* videoDevice = nil;
    for (AVCaptureDeviceType videoDeviceType in self.discoverySession.devices) {
        if (videoDevice != nil) {
            break;
        }
        videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:videoDeviceType
                                                         mediaType:AVMediaTypeVideo
                                                          position:AVCaptureDevicePositionUnspecified];
    }
    
    if (!videoDevice) {
        videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    self.videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&e];
    if (!self.videoDeviceInput) {
        if ([self.delegate respondsToSelector:@selector(captureController:ConfigureSessionFailedWithError:)]) {
            [self.delegate captureController:nil ConfigureSessionFailedWithError:e];
            return SessionSetupResultFailed;
        }
    }
    if([self.session canAddInput:self.videoDeviceInput]) {
        [self.session addInput:self.videoDeviceInput];
        if (SESSION_DEBUG_INFO) {
            NSLog(@"[CaptureController debug info] seesion add video devices input: %@", videoDevice);
        }
    }
    
    // add photo output
    self.photoOutput = [AVCapturePhotoOutput new];
    self.photoOutput.livePhotoCaptureEnabled = self.photoOutput.livePhotoCaptureSupported;
    if ([self.session canAddOutput:self.photoOutput]) {
        [self.session addOutput:self.photoOutput];
        if (SESSION_DEBUG_INFO) {
            NSLog(@"[CaptureController debug info] session add output: %@", self.photoOutput);
        }
    }
    
    [self.session commitConfiguration];
    return SessionSetupResultSuccess;
}

- (void)setPreviewLayer:(VideoPreviewView*)view {
    view.captureSession = self.session;
    view.delegate = self;
    
}

- (void)startSession {
    //startRunning method is a blocking call which can take some time
    if (!self.session.running) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
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
}


- (void)removeSessionObserver {
    NSNotificationCenter* defaultNC = [NSNotificationCenter defaultCenter];
    @try {
        //        [defaultNC removeObserver:self name:AVCaptureSessionRuntimeErrorNotification object:self.session];
        //        [defaultNC removeObserver:self name:AVCaptureSessionDidStartRunningNotification object:self.session];
        //        [defaultNC removeObserver:self name:AVCaptureSessionDidStopRunningNotification object:self.session];
        [defaultNC removeObserver:self];
    } @catch (NSException *exception) {
        //do nothing
    }
}


//
// MARK: - switch capture mode
//
- (BOOL)switchToMode:(CaptureMode)mode {
    BOOL success = [self configSessionForMode:mode];
    if (success) {
        [self enumerateDeviceForMode:mode];
        [self startSession];
        self.currentCaptureMode = mode;
        if ([self.delegate respondsToSelector:@selector(captureController:EnterCaptureMode:)]) {
            [self.delegate captureController:self
                            EnterCaptureMode:mode];
        }
    }
    return success;
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
            self.movieOutput = nil;
        }
        [self.session commitConfiguration];
    }
    
    
    
    else if (mode == CaptureModeVideo) {
        [self.session beginConfiguration];
        self.session.sessionPreset = AVCaptureSessionPresetMedium;
        if (!self.movieOutput) {
            self.movieOutput = [AVCaptureMovieFileOutput new];
            if ([self.session canAddOutput:self.movieOutput]) {
                [self.session addOutput:self.movieOutput];
                if (SESSION_DEBUG_INFO) {
                    NSLog(@"[CaptureController debug info] session add output: %@", self.movieOutput);
                }
            } else {
                [self.session commitConfiguration];
                return FALSE;
            }
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


//
// MARK: - videoPreview delegate
//
- (void)tapToFocusAndExposureAtPoint:(CGPoint)point {
    NSLog(@"tapToFocusAndExposureAtPoint: (%f, %f)", point.x, point.y);
}


- (void)tapToResetFocusAndExposure {
    NSLog(@"tapToResetFocusAndExposure");
}


@end
