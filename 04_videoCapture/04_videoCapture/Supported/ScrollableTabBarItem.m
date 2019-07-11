//
//  ScrollableTabBarItem.m
//  04_videoCapture
//
//  Created by sy on 2019/7/11.
//  Copyright © 2019 sy. All rights reserved.
//

#import "ScrollableTabBarItem.h"

@interface ScrollableTabBarItem ()

@property (strong, nonatomic) UILabel* titleLable;

@end

@implementation ScrollableTabBarItem

- (instancetype)initWithTitleString:(NSString *)title {
    self = [super init];
    if (self) {
        self.titleLable = [[UILabel alloc] init];
        self.titleLable.text = title;
        self.titleLable.textColor = [UIColor whiteColor];
        [self.titleLable sizeToFit];
        [self addSubview:self.titleLable];
        self.frame = self.titleLable.frame;
    }
    return self;
}


- (void)setSelected {
    self.titleLable.textColor = [UIColor redColor];
    self.layer.transform = CATransform3DMakeScale(1.15, 1.15, 1.15);
}

- (void)setDeselected {
    self.titleLable.textColor = [UIColor whiteColor];
    self.layer.transform = CATransform3DMakeScale(0.85, 0.85, 0.85);
}

@end
