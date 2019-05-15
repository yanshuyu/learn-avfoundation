//
//  UIVerticalSlider.m
//  01_audioPlaybackAndRecord
//
//  Created by sy on 2019/5/10.
//  Copyright © 2019 sy. All rights reserved.
//

#import "UIVerticalSlider.h"

@interface UIVerticalSlider ()

@end


@implementation UIVerticalSlider


- (instancetype)init {
    if( [super init] ) {
        [self setUpView];
        return self;
    }
    
    return nil;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpView];
        return self;
    }
    return nil;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setUpView];
        return self;
    }
    return nil;
}


- (void) setUpView {
    self._slider = [[UISlider alloc]init];
    [self addSubview:self._slider];
    [self updateView];
}


- (void) updateView {
    self._slider.transform = CGAffineTransformRotate(CGAffineTransformIdentity, -M_PI_2);
    CGRect bounds = self._slider.bounds;
    bounds.size.width = self.bounds.size.height;
    self._slider.bounds = bounds;
    self._slider.center = CGPointMake(self.bounds.origin.x + self.bounds.size.width*0.5, self.bounds.origin.y + self.bounds.origin.y + self.bounds.size.height*0.5);

}


- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateView];
  }


// minVal maxVal setter & getter
- (void) setMinVal: (CGFloat)val {
    self._slider.minimumValue = val;
}


- (CGFloat) getMinVal {
    return self._slider.minimumValue;
}


- (void) setMaxVal:(CGFloat)val {
    self._slider.maximumValue = val;
}


- (CGFloat) getMaxVal {
    return self._slider.maximumValue;
}

- (void) setVal:(CGFloat)val {
    if (val < self.minVal) {
        val = self.minVal;
    }
    
    if (val > self.maxVal) {
        self.val = self.maxVal;
    }
    
    self._slider.value = val;
}

- (CGFloat) getVal {
    return self._slider.value;
}

- (BOOL) getContinues {
    return self._slider.isContinuous;
}

- (void) setContinues:(BOOL)isContinues {
    [self._slider setContinuous:isContinues];
}

@end
