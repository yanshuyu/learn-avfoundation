//
//  VideoControlView.h
//  03_videoPlayer
//
//  Created by sy on 2019/6/22.
//  Copyright © 2019 sy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoControlDelegate.h"
#import "VideoChapterItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface VideoControlView : UIView

@property (weak, nonatomic) id<VideoControlDelegate> delegate;
@property (strong, nonatomic) NSMutableArray<VideoChapterItem*>* chapters;


- (instancetype)initWithNib:(NSString*)name Delegate:(id<VideoControlDelegate>)delegate;
- (BOOL)loadNib:(NSString*)name Options:(nullable NSDictionary<UINibOptionsKey,id> *)options;

// playback control
- (void)play;
- (void)beginAutoPlay;
- (void)pause;
- (void)beginScrub:(float)percent;
- (void)scrubbingToPercent:(float)percent;
- (void)endedScrub:(float)percent;
- (void)changeVideoGravity:(AVLayerVideoGravity)gravity;
- (void)changeSpeed:(float)speed;
- (void)changeVolum:(float)volum;
- (void)toggleScreen;
- (void)toggleSubtitle;
- (void)close;

// common user interface
- (void)setTitle:(NSString*)title;
- (void)toggleChapter;
- (void)setCurrentTime:(CMTime)current remainTime:(CMTime)remain;
- (void)setCacheLoadingProgress:(float)percent;
- (void)startLoadingActivity;
- (void)stopLoadingActivity;

@end

NS_ASSUME_NONNULL_END
