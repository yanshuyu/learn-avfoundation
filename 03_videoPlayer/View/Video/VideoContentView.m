//
//  VideoContentView.m
//  03_videoPlayer
//
//  Created by sy on 2019/6/23.
//  Copyright © 2019 sy. All rights reserved.
//


#import "VideoContentView.h"
#import <AVFoundation/AVFoundation.h>

@implementation VideoContentView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}


- (instancetype)initWithPlayer:(AVPlayer *)player {
    self = [super init];
    if (self) {
        [self setPlayer:player];
        //self.playerLayer.backgroundColor = (__bridge CGColorRef _Nullable)([UIColor blackColor]);
    }
    return self;
}

- (void)setPlayer:(AVPlayer *)player {
    self.playerLayer.player = player;
}

- (AVPlayer *)player {
    return self.playerLayer.player;
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer*)self.layer;
}

@end
