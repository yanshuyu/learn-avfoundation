//
//  ScrollableTabBar.m
//  04_videoCapture
//
//  Created by sy on 2019/7/11.
//  Copyright © 2019 sy. All rights reserved.
//

#import "ScrollableTabBar.h"

@interface ScrollableTabBar ()

@property (strong, nonatomic) NSArray<ScrollableTabBarItem*>* barItems;
@property (nonatomic) float itemSpace;
@property (strong, nonatomic) UIImageView* selectedIndicator;
@property (strong, nonatomic) UIView* barItemsContainer;
@property (readwrite, nonatomic) int selectedIndex;
@property (strong, nonatomic) UIPanGestureRecognizer* panGesture;
@property (nonatomic) CGPoint lastPanTranslation;
@property (nonatomic) CGPoint lastPanItemPos;

@end


@implementation ScrollableTabBar

- (instancetype)initWithFrame:(CGRect)frame Items:(NSArray<ScrollableTabBarItem*>*)items
                    ItemSpace:(float)itemSpace
        SelectedItemIndicator:(UIImageView*)selectIndicator
                     Delegate:(id<ScrollableTabBarDelegate>)delegate {
    self = [super initWithFrame:frame];
    if (self) {
        self.delegate = delegate;
        self.lastPanTranslation = CGPointZero;
        self.selectedIndex = -1;
        self.barItems = items;
        self.itemSpace = itemSpace;
        self.selectedIndicator = selectIndicator;
        [self setupView];
        [self setupInteraction];
        [self jumpToItemAtIndex:0 Animated:FALSE];
        self.interactionEnabled = TRUE;
    }
    
    return self;
}

- (void)setupView {
    if (SCROLLABLE_TABBAR_DEBUG_MODE) {
        self.layer.borderWidth = 1;
        self.layer.borderColor = [UIColor blueColor].CGColor;
    }
    
    // setup indicator
    if (SCROLLABLE_TABBAR_DEBUG_MODE) {
        self.selectedIndicator.layer.borderWidth = 1;
        self.selectedIndicator.layer.borderColor = [UIColor blueColor].CGColor;
    }
    [self addSubview:self.selectedIndicator];
    self.selectedIndicator.center = CGPointMake(self.bounds.size.width * 0.5,
                                                self.bounds.size.height - self.selectedIndicator.frame.size.height*0.5);
    
    //setup scrollable items bar
    float totalItemWidth = 0;
    float maxItemHeight = 0;
    for (ScrollableTabBarItem* item in self.barItems) {
        CGSize itemSize = item.frame.size;
        totalItemWidth += itemSize.width;
        maxItemHeight = itemSize.height > maxItemHeight ? itemSize.height : maxItemHeight;
    }
    totalItemWidth += (self.barItems.count - 1) * self.itemSpace;
    self.barItemsContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, totalItemWidth, maxItemHeight)];
    float offset = 0;
    for (ScrollableTabBarItem* item in self.barItems) {
        if (SCROLLABLE_TABBAR_DEBUG_MODE) {
            item.layer.borderWidth = 1;
            item.layer.borderColor = [UIColor blueColor].CGColor;
        }
        [self.barItemsContainer addSubview:item];
        item.center = CGPointMake(offset + item.frame.size.width * 0.5, maxItemHeight * 0.5);
        offset += item.frame.size.width + self.itemSpace;
    }
    [self addSubview:self.barItemsContainer];
    CGPoint pos = CGPointZero;
    pos.x = self.barItemsContainer.center.x;
    pos.y = self.frame.size.height - self.selectedIndicator.frame.size.height - maxItemHeight * 0.5;
    self.barItemsContainer.center = pos;
    
    for (ScrollableTabBarItem* item in self.barItems) {
        [item setDeselected];
    }
    
}

- (void)setupInteraction {
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                              action:@selector(handlePanGesture:)];
    [self addGestureRecognizer:self.panGesture];
}

- (BOOL)interactionEnabled {
    return self.panGesture.enabled;
}

- (void)setInteractionEnabled:(BOOL)interactionEnabled {
    self.panGesture.enabled = interactionEnabled;
}

- (void)selectItemAtIndex:(int)index {
    if (self.selectedIndex >= 0 && self.selectedIndex < self.barItems.count) {
        ScrollableTabBarItem* oldItem = [self.barItems objectAtIndex:self.selectedIndex];
        [oldItem setDeselected];
        if ([self.delegate respondsToSelector:@selector(scrollableTabBar:DeselectItem:AtIndex:)]) {
            [self.delegate scrollableTabBar:self
                               DeselectItem:oldItem
                                    AtIndex:self.selectedIndex];
        }
    }
    
    if (index >= 0 && index < self.barItems.count) {
        ScrollableTabBarItem* item = [self.barItems objectAtIndex:index];
        [item setSelected];
        self.selectedIndex = index;
        if ([self.delegate respondsToSelector:@selector(scrollableTabBar:SelectItem:AtIndex:)]) {
            [self.delegate scrollableTabBar:self
                                 SelectItem:item
                                    AtIndex:index];
        }
    }
}


- (void)jumpToItemAtIndex:(uint)index Animated:(BOOL)animated {
    if (index < 0 || index >= self.barItems.count) {
        return;
    }
    
    ScrollableTabBarItem* toItem = self.barItems[index];
    CGPoint currentPoint = [self.barItemsContainer.layer convertPoint:toItem.center toLayer:self.layer];
    CGPoint targetPoint = self.selectedIndicator.center;
    CGFloat offset = targetPoint.x - currentPoint.x;
    
    if (!animated) {
        self.barItemsContainer.center = CGPointMake(self.barItemsContainer.center.x + offset, self.barItemsContainer.center.y);
        if (self.selectedIndex != index) {
            [self selectItemAtIndex:index];
        }
    } else {
        [UIView animateWithDuration:0.5 animations:^{
            [UIView animateWithDuration:0.05
                             animations:^{
                                 self.barItemsContainer.center = CGPointMake(self.barItemsContainer.center.x + offset, self.barItemsContainer.center.y);
                             }
                             completion:^(BOOL finished) {
                                 if (self.selectedIndex != index) {
                                     [self selectItemAtIndex:index];
                                 }
                             }];
        }];
    }
}



- (void)handlePanGesture:(UIPanGestureRecognizer*)gesture {
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            self.lastPanTranslation = CGPointZero;
            self.lastPanItemPos = [self convertPoint:self.barItems[self.selectedIndex].center fromView:self.barItems[self.selectedIndex]];
            if ([self.delegate respondsToSelector:@selector(scrollableTabBar:beginUserScrollingFromSelectedIndex:)]) {
                [self.delegate scrollableTabBar:self
            beginUserScrollingFromSelectedIndex:self.selectedIndex];
            }
            break;
        case UIGestureRecognizerStateChanged: {
            CGFloat minXTranslation = self.barItems.lastObject.frame.size.width - self.barItemsContainer.frame.size.width * 0.5;
            CGFloat maxXTranslation = self.barItemsContainer.frame.size.width * 0.5 - self.barItems.firstObject.frame.size.width + self.frame.size.width;
            CGPoint currentTranslation = [gesture translationInView:self];
            CGFloat detalXTranslation = currentTranslation.x - self.lastPanTranslation.x;
            self.lastPanTranslation = currentTranslation;
            CGFloat xTranslation = self.barItemsContainer.center.x + detalXTranslation;
            xTranslation = xTranslation < minXTranslation ? minXTranslation : xTranslation;
            xTranslation = xTranslation > maxXTranslation ? maxXTranslation : xTranslation;
            self.barItemsContainer.center = CGPointMake(xTranslation, self.barItemsContainer.center.y);
            
            CGPoint selectedItemPos = [self convertPoint:self.barItems[self.selectedIndex].center fromView:self.barItems[self.selectedIndex]];
            CGSize selectedItemSize = self.barItems[self.selectedIndex].bounds.size;
            float offset = selectedItemPos.x - self.lastPanItemPos.x;
            float percent = MIN(1,fabs(offset / (selectedItemSize.width * 0.5)));
            if ([self.delegate respondsToSelector:@selector(scrollableTabBar:userScrollingWithSelectedItemOffset:complectionPercent:)]) {
                [self.delegate scrollableTabBar:self
            userScrollingWithSelectedItemOffset:offset
                             complectionPercent:percent];
            }
            
            break;
        }
        case UIGestureRecognizerStateEnded: {
            self.lastPanTranslation = CGPointZero;
            [self autoJumpToNearestItem];
            if ([self.delegate respondsToSelector:@selector(scrollableTabBar:finishUserScrollingToSelectedIndex:)]) {
                [self.delegate scrollableTabBar:self
             finishUserScrollingToSelectedIndex:self.selectedIndex];
            }
        }
        default:
            break;
    }
}


- (void)autoJumpToNearestItem {
    CGPoint testPoint = CGPointZero;
    testPoint.x = self.selectedIndicator.center.x;
    testPoint.y = self.selectedIndicator.center.y - self.selectedIndicator.frame.size.height * 0.5 - self.barItemsContainer.frame.size.height * 0.5;
    testPoint = [self.barItemsContainer.layer convertPoint:testPoint fromLayer:self.layer];
    int nearestIndex = -1;
    for (ScrollableTabBarItem* item in self.barItems) {
        CGPoint p = [item.layer convertPoint:testPoint fromLayer:self.barItemsContainer.layer];
        if ([item.layer containsPoint:p]) {
            nearestIndex = (int)[self.barItems indexOfObject:item];
            break;
        }
    }
    
    if (nearestIndex == -1) {
        for (ScrollableTabBarItem* item in self.barItems) {
            if (item.center.x > testPoint.x) {
                nearestIndex = (int)[self.barItems indexOfObject:item];
                break;
            }
        }
    }
    
    if (nearestIndex == -1) {
        nearestIndex = (int)self.barItems.count - 1;
    }
    
    [self jumpToItemAtIndex:nearestIndex Animated:FALSE];
}

@end
