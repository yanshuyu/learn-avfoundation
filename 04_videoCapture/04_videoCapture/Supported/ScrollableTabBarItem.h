//
//  ScrollableTabBarItem.h
//  04_videoCapture
//
//  Created by sy on 2019/7/11.
//  Copyright © 2019 sy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ScrollableTabBarItem : UIView

- (instancetype)initWithTitleString:(NSString*)title;

- (void)setSelected;
- (void)setDeselected;

@end

NS_ASSUME_NONNULL_END
