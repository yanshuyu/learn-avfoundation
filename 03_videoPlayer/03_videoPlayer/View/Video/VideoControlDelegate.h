//
//  VideoControllerDelegate.h
//  03_videoPlayer
//
//  Created by sy on 2019/6/20.
//  Copyright © 2019 sy. All rights reserved.
//
#ifndef VideoControllerDelegate_h
#define VideoControllerDelegate_h
#import <AVFoundation/AVFoundation.h>

@protocol VideoControlDelegate <NSObject>

- (void)doPlay;
- (void)doPause;
- (void)doBeginScrub:(float)percent;
- (void)doScrubbingToPercent:(float)percent;
- (void)doEndedScrub:(float)percent;
- (void)doScrubbingToTime:(CMTime)time;
- (void)doChangeVideoGravity:(AVLayerVideoGravity)gravity;
- (void)doChangeVideoSpeed:(float)speed;
- (void)doChangeVideoVolum:(float)volum;
- (void)doToggleFullScreen;
- (void)doToggleSubtitle;
- (void)doToggleChapters;
- (void)doClose;

@end

#endif /* VideoControllerDelegate_h */
