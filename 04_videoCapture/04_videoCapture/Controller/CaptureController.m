//
//  SYCaptureController.m
//  04_videoCapture
//
//  Created by sy on 2019/7/9.
//  Copyright © 2019 sy. All rights reserved.
//

#import "CaptureController.h"
#import <Photos/Photos.h>

@interface CaptureController () <AVCapturePhotoCaptureDelegate>

//
// session configuration
//
@property (strong, nonatomic) AVCaptureSession* session;
@property (strong, nonatomic) AVCaptureDeviceDiscoverySession* discoverySession;
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


//
// MARK: - session configuration
//
- (void)setupSessionWithCompletionHandle:(void(^)(void))completionHandler {
    // check video device authorized state
    AVAuthorizationStatus videoAuthorizedStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    AVAuthorizationStatus audioAuthorizedStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (videoAuthorizedStatus == AVAuthorizationStatusDenied || audioAuthorizedStatus == AVAuthorizationStatusDenied) {
        if ([self.delegate respondsToSelector:@selector(captureController:ConfigureSessionResult:Error:)])
            [self.delegate captureController:self ConfigureSessionResult:SessionSetupResultUnAuthorized Error:nil];
        return;
    }
    
    if (videoAuthorizedStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                                 completionHandler:^(BOOL granted) {
                                     if (!granted) {
                                         if ([self.delegate respondsToSelector:@selector(captureController:ConfigureSessionResult:Error:)])
                                             [self.delegate captureController:self ConfigureSessionResult:SessionSetupResultUnAuthorized Error:nil];
                                     } else {
                                         if (audioAuthorizedStatus == AVAuthorizationStatusNotDetermined) {
                                             [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                                                 if (!granted) {
                                                     if ([self.delegate respondsToSelector:@selector(captureController:ConfigureSessionResult:Error:)])
                                                         [self.delegate captureController:self ConfigureSessionResult:SessionSetupResultUnAuthorized Error:nil];
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
                    [self.delegate captureController:self ConfigureSessionResult:SessionSetupResultUnAuthorized Error:nil];
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
                [self.delegate captureController:self ConfigureSessionResult:SessionSetupResultFailed Error:e];
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
                [self.delegate captureController:self ConfigureSessionResult:SessionSetupResultFailed Error:nil];
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
                    [self.delegate captureController:self ConfigureSessionResult:SessionSetupResultFailed Error:e];
                [self.session commitConfiguration];
                return;
            }
        }
        
        if([self.session canAddInput:self.videoDeviceInput]) {
            [self.session addInput:self.videoDeviceInput];
            if (SESSION_DEBUG_INFO) {
                NSLog(@"[CaptureController debug info] seesion add video devices input: %@", self.videoDeviceInput.device);
            }
        }else {
            if ([self.delegate respondsToSelector:@selector(captureController:ConfigureSessionResult:Error:)])
                [self.delegate captureController:self ConfigureSessionResult:SessionSetupResultFailed Error:nil];
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
                [self.delegate captureController:self ConfigureSessionResult:SessionSetupResultFailed Error:nil];
            [self.session commitConfiguration];
            return;
        }
        
        [self.session commitConfiguration];
        [self startSession];
        
        if (completionHandler) {
            completionHandler();
        }
    });
}

- (void)setPreviewLayer:(VideoPreviewView*)view {
    view.captureSession = self.session;
    view.delegate = self;
    
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
// MARK: - capture photo
//
- (void)capturePhoto {
    if (self.currentCaptureMode != CaptureModePhoto) {
        if ([self.delegate respondsToSelector:@selector(captureController:InavailbleCaptureRequestForMode:)]) {
            [self.delegate captureController:self
             InavailbleCaptureRequestForMode:self.currentCaptureMode];
        }
        return;
    }
    
    
    AVCapturePhotoSettings* captureSetting = nil;
    if ([self.photoOutput.availablePhotoCodecTypes containsObject:AVVideoCodecTypeHEVC] ) {
        captureSetting = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey:AVVideoCodecTypeHEVC}];
    } else {
        captureSetting = [AVCapturePhotoSettings photoSettings];
    }
    captureSetting.highResolutionPhotoEnabled  = self.photoOutput.highResolutionCaptureEnabled;
    captureSetting.flashMode = AVCaptureFlashModeAuto;
    captureSetting.autoStillImageStabilizationEnabled = self.photoOutput.stillImageStabilizationSupported;
    self.photoOutput.livePhotoCaptureEnabled = FALSE;
    
    [self.photoCaptureSettingsOnProgressing setObject:captureSetting forKey:[NSNumber numberWithLongLong:captureSetting.uniqueID]];
    [self.photoOutput capturePhotoWithSettings:captureSetting
                                      delegate:self];
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


//
// MARK: - photo / video capture protocol
//
- (void)savePhotoToPhotoLibraryWithCaptureUUID:(int64_t)uuid {
    PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
    if (authorizationStatus == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                [self doSavePhotoToPhotoLibraryWithCaptureUUID:uuid];
            } else {
                if ([self.delegate respondsToSelector:@selector(captureController:SavePhotoData:Result:Error:)]){
                    [self.delegate captureController:self
                                       SavePhotoData:nil
                                              Result:PhotoSavedResultUnAuthorized
                                               Error:nil];
                }
            }
        }];
        
        return;
    } else if (authorizationStatus == PHAuthorizationStatusDenied) {
        if ([self.delegate respondsToSelector:@selector(captureController:SavePhotoData:Result:Error:)]){
            [self.delegate captureController:self
                               SavePhotoData:nil
                                      Result:PhotoSavedResultUnAuthorized
                                       Error:nil];
            
        }
        
        return;
    }
    
    [self doSavePhotoToPhotoLibraryWithCaptureUUID:uuid];
}


- (void)doSavePhotoToPhotoLibraryWithCaptureUUID:(int64_t)uuid {
    NSNumber* key = [NSNumber numberWithLongLong:uuid];
    AVCapturePhotoSettings* captureSetting = [self.photoCaptureSettingsOnProgressing objectForKey:key];
    NSData* photoData = [self.photoCaptureDataOnProgressing objectForKey:key];
    if (SESSION_DEBUG_INFO) {
        NSLog(@"saving photo data at address: %d for key: %@", (int)photoData.bytes, key);
    }
    assert(captureSetting != nil && photoData != nil);
    
    [[PHPhotoLibrary sharedPhotoLibrary]performChanges:^{
        PHAssetResourceCreationOptions* options = [PHAssetResourceCreationOptions new];
        options.uniformTypeIdentifier = captureSetting.processedFileType;
        PHAssetCreationRequest* newAssetRequest = [PHAssetCreationRequest creationRequestForAsset];
        
        [newAssetRequest addResourceWithType:PHAssetResourceTypePhoto
                                        data:photoData
                                     options:options];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            if (SESSION_DEBUG_INFO) {
                NSLog(@"saving photo data at address: %d for key: %@ success", (int)photoData.bytes, key);
            }
            dispatch_async(self.sessionQueue, ^{
                [self.photoCaptureSettingsOnProgressing removeObjectForKey:key];
                [self.photoCaptureDataOnProgressing removeObjectForKey:key];
            });
            
        }
        PhotoSavedResult reslut = success ? PhotoSavedResultSuccess : PhotoSavedResultFailed;
        if ([self.delegate respondsToSelector:@selector(captureController:SavePhotoData:Result:Error:)]) {
            [self.delegate captureController:self
                               SavePhotoData:photoData
                                      Result:reslut
                                       Error:error];
        }
    }];
}


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
            NSLog(@"Generating photo data at address:%d, for key: %@ success", (int)photoData.bytes, key);
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
        dispatch_async(self.sessionQueue, ^{
            [self savePhotoToPhotoLibraryWithCaptureUUID:resolvedSettings.uniqueID];
        });
    }
}

@end

