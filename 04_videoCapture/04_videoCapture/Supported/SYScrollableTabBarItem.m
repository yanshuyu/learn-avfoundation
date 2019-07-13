//
//  SYScrollableTabBarItem.m
//  04_videoCapture
//
//  Created by sy on 2019/7/12.
//  Copyright © 2019 sy. All rights reserved.
//

#import "SYScrollableTabBarItem.h"

@implementation SYScrollableTabBarItem

- (instancetype)initWithTitleString:(NSString *)title CaptureMode:(CaptureMode)mode {
    self = [super initWithTitleString:title];
    if (self) {
        self.mode = mode;
    }
    return  self;
}

@end
