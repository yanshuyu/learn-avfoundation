//
//  ScrollableTabBar.h
//  04_videoCapture
//
//  Created by sy on 2019/7/11.
//  Copyright © 2019 sy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScrollableTabBarItem.h"

NS_ASSUME_NONNULL_BEGIN

#define SCROLLABLE_TABBAR_DEBUG_MODE 0

@class ScrollableTabBar;





@protocol ScrollableTabBarDelegate <NSObject>

@optional
- (void)scrollableTabBar:(ScrollableTabBar*)bar SelectItem:(ScrollableTabBarItem*)item AtIndex:(int)index;
- (void)scrollableTabBar:(ScrollableTabBar *)bar DeselectItem:(ScrollableTabBarItem *)item AtIndex:(int)index;

@end





@interface ScrollableTabBar : UIView

@property (weak, nonatomic) id<ScrollableTabBarDelegate> delegate;
@property (readonly, nonatomic) int selectedIndex;

- (instancetype)initWithFrame:(CGRect)frame Items:(NSArray<ScrollableTabBarItem*>*)items
                    ItemSpace:(float)itemSpace
        SelectedItemIndicator:(UIImageView*)selectIndicator
                     Delegate:(id<ScrollableTabBarDelegate>)delegate;


- (void)jumpToItemAtIndex:(uint)index Animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
