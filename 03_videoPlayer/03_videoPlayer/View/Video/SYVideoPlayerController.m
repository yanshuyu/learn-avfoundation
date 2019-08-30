//
//  SYVideoPlayerController.m
//  03_videoPlayer
//
//  Created by sy on 2019/6/23.
//  Copyright © 2019 sy. All rights reserved.
//

#import "SYVideoPlayerController.h"
#import "SYVideoControlView.h"

@implementation SYVideoPlayerController

- (Class)controlLayerClass {
    return [SYVideoControlView class];
}

@end
