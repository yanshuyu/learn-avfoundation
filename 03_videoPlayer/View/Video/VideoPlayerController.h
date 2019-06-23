//
//  VideoPlayerController.h
//  03_videoPlayer
//
//  Created by sy on 2019/6/22.
//  Copyright © 2019 sy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoContentView.h"
#import "VideoControlView.h"
#import "VideoControlDelegate.h"
#import "SYVideoControlView.h"

NS_ASSUME_NONNULL_BEGIN

@interface VideoPlayerController : NSObject <VideoControlDelegate>

@property (strong, nonatomic, readonly) UIView* view;
@property (strong, nonatomic, setter=setUrl:) NSURL* url;
@property (weak, nonatomic, nullable) UIViewController* embedViewController;

- (instancetype)initWithURL:(NSURL*)url;
- (Class)controlLayerClass;
- (Class)contentLayerClass;
- (void) clenup;


@end

NS_ASSUME_NONNULL_END
