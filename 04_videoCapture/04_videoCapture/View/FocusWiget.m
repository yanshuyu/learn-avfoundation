//
//  FocusWiget.m
//  04_videoCapture
//
//  Created by sy on 2019/7/9.
//  Copyright © 2019 sy. All rights reserved.
//

#import "FocusWiget.h"

@implementation FocusWiget

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame color:[UIColor whiteColor]];
}

- (instancetype)initWithFrame:(CGRect)frame color:(UIColor *)color {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.borderColor = color.CGColor;
        self.layer.borderWidth = 2;
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGFloat w = self.frame.size.width;
    CGFloat h = self.frame.size.height;
    [self drawLintFromPoint:CGPointMake(0, h * 0.5) ToPoint:CGPointMake(20, h * 0.5)];
    [self drawLintFromPoint:CGPointMake(w * 0.5, h) ToPoint:CGPointMake(w * 0.5, h - 20)];
    [self drawLintFromPoint:CGPointMake(w, h * 0.5) ToPoint:CGPointMake(w - 20, h * 0.5)];
    [self drawLintFromPoint:CGPointMake(w * 0.5, 0) ToPoint:CGPointMake(w * 0.5, 20)];
}

- (void)drawLintFromPoint:(CGPoint)start ToPoint:(CGPoint)end {
    UIBezierPath* path = [UIBezierPath new];
    path.lineWidth = self.layer.borderWidth;
    [path moveToPoint:start];
    [path addLineToPoint:end];
    [path closePath];
    [[UIColor colorWithCGColor:self.layer.borderColor] setStroke];
    [path stroke];
}

@end
