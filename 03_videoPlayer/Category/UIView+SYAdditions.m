//
//  UIView+SYAdditions.m
//  03_videoPlayer
//
//  Created by sy on 2019/6/22.
//  Copyright © 2019 sy. All rights reserved.
//

#import "UIView+SYAdditions.h"

@implementation UIView (SYAdditions)

- (void)removeAllSubViews {
    NSUInteger count = self.subviews.count;
    while (count > 0) {
        UIView* child = self.subviews[--count];
        [child removeFromSuperview];
    }
}

@end
