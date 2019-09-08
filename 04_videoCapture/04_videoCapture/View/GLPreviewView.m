//
//  GLPreviewView.m
//  04_videoCapture
//
//  Created by sy on 2019/9/8.
//  Copyright © 2019 sy. All rights reserved.
//

#import "GLPreviewView.h"
#import <GLKit/GLKit.h>
#import "../Supported/ContextManager.h"

@interface GLPreviewView ()

@property (strong, nonatomic) GLKView* glkView;
@property (strong, nonatomic) CIContext* ciContext;

@end

@implementation GLPreviewView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupview];
    }
    return self;
}


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupview];
    }
    return self;
}

- (void)setupview {
    self.ciContext = [ContextManager shareInstance].shareCIContext;
    EAGLContext* glContext = [ContextManager shareInstance].shareGLContext;
    self.glkView = [[GLKView alloc] initWithFrame:self.bounds context:glContext];
    [self.glkView bindDrawable];
    self.glkView.enableSetNeedsDisplay = FALSE;
    [self addSubview:self.glkView];
}


- (void)renderCIImage:(CIImage *)image {
    CGRect drawRect = CGRectMake(0, 0, self.glkView.drawableWidth, self.glkView.drawableHeight);
    CGRect cropRect = [self centerCropImageRectForSourceRect:image.extent toTargetRect:drawRect];
    [self.ciContext drawImage:image inRect:drawRect fromRect:cropRect];
    [self.glkView display];
}

- (CGRect)centerCropImageRectForSourceRect:(CGRect)srcRect toTargetRect:(CGRect)targetRect {
    CGFloat sourceAspectRatio = srcRect.size.width / srcRect.size.height;
    CGFloat targetAspectRatio = targetRect.size.width  / targetRect.size.height;
    
    CGRect drawRect = srcRect;
    if (sourceAspectRatio > targetAspectRatio) {
        CGFloat scaledHeight = drawRect.size.height * targetAspectRatio;
        drawRect.origin.x += (drawRect.size.width - scaledHeight) / 2.0;
        drawRect.size.width = scaledHeight;
    } else {
        // use full width of the video image, and center crop the height
        drawRect.origin.y += (drawRect.size.height - drawRect.size.width / targetAspectRatio) / 2.0;
        drawRect.size.height = drawRect.size.width / targetAspectRatio;
    }
    
    return drawRect;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    self.glkView.frame = self.bounds;
    NSLog(@"gl view frame: %@", NSStringFromCGRect(self.glkView.frame));
}

@end
