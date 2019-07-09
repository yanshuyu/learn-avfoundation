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


- (void)setPreviewLayer:(AVCaptureVideoPreviewLayer *)layer {
    [layer setSession:self.session];
}


- (void)startSession {
    if (!self.session.running) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
            [self.session startRunning];
        });
    }
}

- (void)stopSession {
    if (self.session.running) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
            [self.session stopRunning];
        });
    }
}

@end
