//
//  AudioRecoderController.m
//  02_audioRecoder
//
//  Created by sy on 2019/5/23.
//  Copyright © 2019 sy. All rights reserved.
//

#import "AudioRecoderController.h"




@interface AudioRecoderController () <AVAudioRecorderDelegate>



@end

@implementation AudioRecoderController
//
// create instance of AudioRecoderController
//
- (instancetype)init
{
    NSDictionary* settings = @{ AVFormatIDKey : @(kAudioFormatAppleIMA4),
                                AVSampleRateKey : @44100.0f,
                                AVNumberOfChannelsKey : @1,
                                AVEncoderBitDepthHintKey : @16,
                                AVEncoderAudioQualityKey : @(AVAudioQualityMedium),
                                };

    return [self initWithURL:[self getTemproryURLForRecording] Settings:settings];
    
}

- (instancetype)initWithURL:(NSURL*)url Settings:(NSDictionary<NSString*, id>*)settings {
    self = [super init];
    if (self) {
        NSError* e;
        self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:url
                                                         settings:settings
                                                            error:&e];
        if (!self.audioRecorder) {
            NSLog(@"Failed to create AudioRecoderController instance for reson: %@", e.localizedDescription);
            return nil;
        }
        self.audioRecorder.delegate = self;
        self.delegate = nil;
        [self.audioRecorder prepareToRecord];
    }
    
    return self;
}

//
// controlling record
//
- (BOOL)record {
    BOOL success = [self.audioRecorder record];
    if (self.delegate) {
        [self.delegate audioRecorderControllerRecordBegin:success];
    }
    return success;
}

- (void)pause {
    [self.audioRecorder pause];
    if (self.delegate) {
        [self.delegate audioRecorderControllerRecordPause];
    }
}

- (void)stop {
    [self.audioRecorder stop];
    
}

//
// AudioRecorder Delegate
//
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    if (self.delegate) {
        NSURL* result = flag ? self.audioRecorder.url : nil;
        [self.delegate audioRecorderControllerRecordFinish:flag WithResult:result];
        //[self.audioRecorder prepareToRecord];
    }
}

//
// delete recorded temprory file
//
- (BOOL)clearup:(NSError* _Nullable *)e {
    BOOL success = TRUE;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error;
    success = [fileManager removeItemAtURL:self.audioRecorder.url error:&error];
    if (!success && e) {
        *e = error;
    }
    return success;
}

//
// return temprory file path or url for recording
//
- (NSString*)getTemproryFilePathForRecording {
    NSString* tempDir = NSTemporaryDirectory();
    NSString* tempFile = @"cacheMemo.caf";
    return [tempDir stringByAppendingPathComponent:tempFile];
}

- (NSURL*)getTemproryURLForRecording {
    NSString* path = [self getTemproryFilePathForRecording];
    return [NSURL fileURLWithPath:path];
}

@end
