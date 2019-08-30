//
//  VideoChapterItem.m
//  03_videoPlayer
//
//  Created by sy on 2019/6/22.
//  Copyright © 2019 sy. All rights reserved.
//

#import "VideoChapterItem.h"

@implementation VideoChapterItem

- (instancetype)initWithCMTime:(CMTime)time title:(NSString *)text {
    self = [super init];
    if (self) {
        self.time = time;
        self.title = text;
    }
    return self;
}

@end
