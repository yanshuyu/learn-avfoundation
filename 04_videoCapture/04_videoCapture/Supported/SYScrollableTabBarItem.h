//
//  SYScrollableTabBarItem.h
//  04_videoCapture
//
//  Created by sy on 2019/7/12.
//  Copyright © 2019 sy. All rights reserved.
//

#import "ScrollableTabBarItem.h"
#import "../Controller/CaptureController.h"

NS_ASSUME_NONNULL_BEGIN

@interface SYScrollableTabBarItem : ScrollableTabBarItem
@property (nonatomic) CaptureMode mode;
- (instancetype)initWithTitleString:(NSString *)title CaptureMode:(CaptureMode)mode;
@end

NS_ASSUME_NONNULL_END
