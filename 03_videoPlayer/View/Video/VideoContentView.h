//
//  VideoContentView.h
//  03_videoPlayer
//
//  Created by sy on 2019/6/23.
//  Copyright © 2019 sy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AVPlayerLayer;
@class AVPlayer;

@interface VideoContentView : UIView

@property (nonatomic, setter=setPlayer:) AVPlayer* player;
@property (readonly) AVPlayerLayer* playerLayer;

- (instancetype)initWithPlayer:(AVPlayer*)player;

@end

NS_ASSUME_NONNULL_END
