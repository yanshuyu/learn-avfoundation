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

@end


@implementation CaptureController

//
// MARK: - session configuration
//
- (BOOL)setupCaptureSessionWithPreset:(AVCaptureSessionPreset)preset Error:(NSError* _Nullable*)error {
    self.session = [AVCaptureSession new];
    self.session.sessionPreset = preset;
    [self addSessionSetupObserver];
    
    if (![self setupSessionInput:error]) {
        return FALSE;
    }
    
    if (![self setupSessionOutput:error]) {
        return FALSE;
    }
    
    return TRUE;
}

- (BOOL)setupSessionInput:(NSError* _Nullable*)error {
    AVCaptureDevice* cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput* cameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:cameraDevice
                                                                                error:error];
    if (!cameraDeviceInput) {
        if (error) {
            [self.delegate captureController:self
             ConfigureSessionFailedWithError:*error];
        }
        return FALSE;
    }
    if ([self.session canAddInput:cameraDeviceInput]) {
        [self.session addInput:cameraDeviceInput];
    } else {
        if (error) {
            NSDictionary* info = @{ NSLocalizedDescriptionKey : @"try to add incompatible video input device" };
            __autoreleasing NSError* e = [NSError errorWithDomain:CaptureControllerErrorDomain
                                                             code:CaptureControllerErrorIncompatibleDeviceInput
                                                         userInfo:info];
            
            error = &e;
            [self.delegate captureController:self
             ConfigureSessionFailedWithError:*error];
        }
        return FALSE;
    }
    
    AVCaptureDevice* audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput* audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice
                                                                                error:error];
    if (!audioDeviceInput) {
        if (error) {
            [self.delegate captureController:self
             ConfigureSessionFailedWithError:*error];
        }
        return FALSE;
    }
    if ([self.session canAddInput:audioDeviceInput]) {
        [self.session addInput:audioDeviceInput];
    } else {
        if (error) {
            NSDictionary* info = @{ NSLocalizedDescriptionKey : @"try to add incompatible audio input device" };
            __autoreleasing NSError* e = [NSError errorWithDomain:CaptureControllerErrorDomain
                                                             code:CaptureControllerErrorIncompatibleDeviceInput
                                                         userInfo:info];
            error = &e;
            [self.delegate captureController:self
             ConfigureSessionFailedWithError:*error];
        }
        return FALSE;
    }
    
    return TRUE;
}

- (BOOL)setupSessionOutput:(NSError* _Nullable*)error {
    AVCapturePhotoOutput* photoOutput = [AVCapturePhotoOutput new];
    if ([self.session canAddOutput:photoOutput]) {
        [self.session addOutput:photoOutput];
    } else {
        if (error) {
            NSDictionary* info = @{ NSLocalizedDescriptionKey : @"try to add incompatible photo output device" };
            __autoreleasing NSError* e = [NSError errorWithDomain:CaptureControllerErrorDomain
                                                             code:CaptureControllerErrorIncompatibleDeviceOutput
                                                         userInfo:info];
            error = &e;
            [self.delegate captureController:self
             ConfigureSessionFailedWithError:*error];
        }
        return FALSE;
    }
    
    AVCaptureMovieFileOutput* videoOutput = [AVCaptureMovieFileOutput new];
    if ([self.session canAddOutput:videoOutput]) {
        [self.session addOutput:videoOutput];
    } else {
        if (error) {
            NSDictionary* info = @{ NSLocalizedDescriptionKey : @"try to add incompatible video output device" };
            __autoreleasing NSError* e = [NSError errorWithDomain:CaptureControllerErrorDomain
                                                             code:CaptureControllerErrorIncompatibleDeviceOutput
                                                         userInfo:info];
            error = &e;
            [self.delegate captureController:self
             ConfigureSessionFailedWithError:*error];
        }
        return FALSE;
    }
         
    return TRUE;
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
    [self removeSessionSetupObserver];
}


- (void)addSessionSetupObserver {
    NSNotificationCenter* defaultNC = [NSNotificationCenter defaultCenter];
    [defaultNC addObserver:self
                  selector:@selector(startRunningSessionFailedWithNotification:)
                      name:AVCaptureSessionRuntimeErrorNotification
                    object:self.session];
    [defaultNC addObserver:self
                  selector:@selector(sessionDidStartRunningWithNotification:)
                      name:AVCaptureSessionDidStartRunningNotification
                    object:self.session];
    [defaultNC addObserver:self
                  selector:@selector(sessionDidStopRunningWithNotification:)
                      name:AVCaptureSessionDidStopRunningNotification
                    object:self.session];
}


- (void)removeSessionSetupObserver {
    NSNotificationCenter* defaultNC = [NSNotificationCenter defaultCenter];
    @try {
        [defaultNC removeObserver:self name:AVCaptureSessionRuntimeErrorNotification object:self.session];
        [defaultNC removeObserver:self name:AVCaptureSessionDidStartRunningNotification object:self.session];
        [defaultNC removeObserver:self name:AVCaptureSessionDidStopRunningNotification object:self.session];
    } @catch (NSException *exception) {
        //do nothing
    }
}

- (void)startRunningSessionFailedWithNotification:(NSNotification*)notification {
    [self.delegate captureControllerStartRunningSessionFailed:self];
}

- (void)sessionDidStartRunningWithNotification:(NSNotification*)notification {
    [self.delegate captureControllerSessionDidStartRunning:self];
}

- (void)sessionDidStopRunningWithNotification:(NSNotification*)notification {
    [self.delegate captureControllerSessionDidStopRunning:self];
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
