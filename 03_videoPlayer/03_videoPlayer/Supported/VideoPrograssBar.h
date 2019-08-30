//
//  VideoPrograssBar.h
//  03_videoPlayer
//
//  Created by sy on 2019/6/28.
//  Copyright © 2019 sy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@class VideoPrograssBar;
@protocol VideoPrograssBarDelegate <NSObject>
- (void)videoPrograssBar:(VideoPrograssBar*)videoPrograssBar didBeginScrub:(float)percent;
- (void)videoPrograssBar:(VideoPrograssBar*)videoPrograssBar didScrubToPercent:(float)percent;
- (void)videoPrograssBar:(VideoPrograssBar*)videoPrograssBar didEndedScrub:(float)percent;
@end


IB_DESIGNABLE
@interface VideoPrograssBar : UIView

@property (strong, nonatomic) UISlider* playbackHeader;
@property (strong, nonatomic) UIProgressView* cachePrograss;
@property (weak, nonatomic) id<VideoPrograssBarDelegate> delegate;

- (void)setPlayBackProgress:(float)percent;
- (void)setLoadCacheProgress:(float)percent;

@end

NS_ASSUME_NONNULL_END
