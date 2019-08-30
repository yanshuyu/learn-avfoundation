//
//  VideoPrograssBar.m
//  03_videoPlayer
//
//  Created by sy on 2019/6/28.
//  Copyright © 2019 sy. All rights reserved.
//

#import "VideoPrograssBar.h"


@interface VideoPrograssBar ()

@end



@implementation VideoPrograssBar

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setUpView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setUpView];
    }
    return self;
}


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpView];
    }
    return self;
}


- (void)setUpView {
    self.playbackHeader = [[UISlider alloc] init];
    self.cachePrograss = [[UIProgressView alloc] init];
    [self addSubview:self.cachePrograss];
    [self addSubview:self.playbackHeader];
   
    self.userInteractionEnabled = TRUE;
    self.playbackHeader.userInteractionEnabled = TRUE;
    self.cachePrograss.userInteractionEnabled = FALSE;
    self.playbackHeader.minimumTrackTintColor = [UIColor redColor];
    self.playbackHeader.maximumTrackTintColor = [UIColor clearColor];
    self.cachePrograss.tintColor = [UIColor whiteColor];
    self.cachePrograss.trackTintColor = [UIColor grayColor];
    self.playbackHeader.minimumValue = 0;
    self.playbackHeader.maximumValue = 1;
    
//    [self.playbackHeader addTarget:self
//                            action:@selector(handlePlayheaderTouchedDown)
//                  forControlEvents:UIControlEventTouchDown];
    [self.playbackHeader addTarget:self
                            action:@selector(handlePlayheaderSliding::)
                  forControlEvents:UIControlEventValueChanged];
//    [self.playbackHeader addTarget:self action:@selector(handlePlayheadeTouchedUpInside)
//                  forControlEvents:UIControlEventTouchUpInside];
}


- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect oldFrame = self.playbackHeader.frame;
    oldFrame.size.width = self.frame.size.width+4;
    self.playbackHeader.frame = oldFrame;
    self.playbackHeader.center = CGPointMake(self.frame.size.width * 0.5, self.frame.size.height * 0.5);
    
    oldFrame = self.cachePrograss.frame;
    oldFrame.size.width = self.frame.size.width;
    self.cachePrograss.frame = oldFrame;
    self.cachePrograss.center = self.playbackHeader.center;
}


- (void)handlePlayheaderSliding:(UISlider*)sender :(UIEvent*)event {
//    [self.delegate videoPrograssBar:self
//                  didScrubToPercent:self.playbackHeader.value];
    UITouch* touchEvent = [[event allTouches] anyObject];
    switch (touchEvent.phase) {
        case UITouchPhaseBegan:
            [self.delegate videoPrograssBar:self didBeginScrub:self.playbackHeader.value];
            break;
            
        case UITouchPhaseMoved:
            [self.delegate videoPrograssBar:self didScrubToPercent:self.playbackHeader.value];
            break;
            
        case UITouchPhaseEnded:
            [self.delegate videoPrograssBar:self didEndedScrub:self.playbackHeader.value];
            break;
            
        case UITouchPhaseCancelled:
            [self.delegate videoPrograssBar:self didEndedScrub:self.playbackHeader.value];
            break;
            
        default:
            break;
    }
}

//- (void)handlePlayheaderTouchedDown {
//    [self.delegate videoPrograssBar:self
//                      didBeginScrub:self.playbackHeader.value];
//}
//
//- (void)handlePlayheadeTouchedUpInside {
//    [self.delegate videoPrograssBar:self
//                      didEndedScrub:self.playbackHeader.value];
//}

- (void)setPlayBackProgress:(float)percent {
    self.playbackHeader.value = percent;
}

- (void)setLoadCacheProgress:(float)percent {
    self.cachePrograss.progress = percent;
}




@end
