//
//  VideoPrograssBar.h
//  03_videoPlayer
//
//  Created by sy on 2019/6/28.
//  Copyright © 2019 sy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

IB_DESIGNABLE
@interface VideoPrograssBar : UIView

@property (strong, nonatomic) UISlider* playbackHeader;
@property (strong, nonatomic) UIProgressView* cachePrograss;

- (void)setPlayBackProgress:(float)percent;
- (void)setLoadCacheProgress:(float)percent;

@end

NS_ASSUME_NONNULL_END
