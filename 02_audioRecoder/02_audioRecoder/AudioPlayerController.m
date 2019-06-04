//
//  AudioPlayerController.m
//  02_audioRecoder
//
//  Created by sy on 2019/5/23.
//  Copyright © 2019 sy. All rights reserved.
//

#import "AudioPlayerController.h"
#import <AVFoundation/AVFoundation.h>


@interface AudioPlayerController ()

@property (nonatomic, strong) AVAudioPlayer* audioPlayer;

@end


@implementation AudioPlayerController

//
// Create AudioPlaterController Instance
//
- (instancetype)initWithData:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)outError{
    self = [super init];
    if (self) {
        NSError* e;
        self.audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:&e];
        if (!self.audioPlayer) {
            if (outError) {
                *outError = e;
            }
            return nil;
        }
        [self.audioPlayer prepareToPlay];
    }
    
    return self;
}

- (instancetype)initWithContentsOfURL:(NSURL *)url error:(NSError * _Nullable *)outError {
    self = [super init];
    if (self) {
        NSError* e;
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&e];
        if (!self.audioPlayer) {
            if (outError) {
                *outError = e;
            }
            return  nil;
        }
        [self.audioPlayer prepareToPlay];
    }
    return self;
}

//
// Playback Controll
//
- (BOOL)isPlaying {
    return self.audioPlayer.isPlaying;
}

- (BOOL)play {
    return [self.audioPlayer play];
}

- (void)pause {
    [self.audioPlayer pause];
}

- (void)stop {
    [self.audioPlayer stop];
}



@end
