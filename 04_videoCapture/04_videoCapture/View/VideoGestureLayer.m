//
//  VideoGestureLayer.m
//  04_videoCapture
//
//  Created by sy on 2019/7/30.
//  Copyright © 2019 sy. All rights reserved.
//

#import "VideoGestureLayer.h"
#import "FocusWiget.h"

#define WIGET_SIZE CGRectMake(0, 0, 120, 120)
#define WIGET_COLOR [UIColor colorWithRed:255 green:0 blue:0 alpha:1]
#define WIGET_DELAY_HIDE_TIME 0.8

@interface VideoGestureLayer ()

@property (strong, nonatomic) UITapGestureRecognizer* singleTapGesture;
@property (strong, nonatomic) UITapGestureRecognizer* doubleTapGesture;
@property (strong, nonatomic) UIPinchGestureRecognizer* pinchGesture;
@property (strong, nonatomic) FocusWiget* tapWiget;
@property (strong, nonatomic) FocusWiget* unvisibleWiget;
@property (strong, nonatomic) UIViewPropertyAnimator* zoomAnimator;
@property (strong, nonatomic) UIViewPropertyAnimator* hiddenAnimator;

@end


@implementation VideoGestureLayer

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.backgroundColor = [UIColor clearColor];
    
    self.singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(hanleSingleTap:)];
    self.doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(handleDoubleTap:)];
    self.pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                  action:@selector(handlePinch:)];
    self.doubleTapGesture.numberOfTapsRequired = 2;
    [self.singleTapGesture requireGestureRecognizerToFail:self.doubleTapGesture];
    self.singleTapGesture.cancelsTouchesInView = FALSE;
    self.doubleTapGesture.cancelsTouchesInView = FALSE;
    [self addGestureRecognizer:self.singleTapGesture];
    [self addGestureRecognizer:self.doubleTapGesture];
    [self addGestureRecognizer:self.pinchGesture];
    
    self.tapWiget = [[FocusWiget alloc] initWithFrame:WIGET_SIZE color:WIGET_COLOR];
    self.tapWiget.hidden = TRUE;
    [self addSubview:self.tapWiget];
    
    self.unvisibleWiget = [[FocusWiget alloc] initWithFrame:WIGET_SIZE color:WIGET_COLOR];
    self.unvisibleWiget.hidden = TRUE;
    [self addSubview:self.unvisibleWiget];
    
    self.tapToFocusAndExposureEnabled = FALSE;
    self.pinchToZoomCameraEnabled = FALSE;
}

- (void)hanleSingleTap:(UIGestureRecognizer*)gesture {
    CGPoint point = [gesture locationInView:self];
    [self runTapWigetZoomAnimationTo:point];
    if ([self.delegate respondsToSelector:@selector(videoGestureLayer:TapToFocusAndExposureAtLayerPoint:)]) {
        [self.delegate videoGestureLayer:self
       TapToFocusAndExposureAtLayerPoint:point];
    }
}

- (void)handleDoubleTap:(UIGestureRecognizer*)gesture {
    CGPoint point = [gesture locationInView:self];
    [self runTapWigetZoomAnimationTo:CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))];
    if ([self.delegate respondsToSelector:@selector(videoGestureLayer:TapToResetFocusAndExposureAtLayerPoint:RecommandedPoint:)]) {
        [self.delegate videoGestureLayer:self
        TapToResetFocusAndExposureAtLayerPoint:point
                           RecommandedPoint:CGPointMake(self.bounds.size.width*0.5, self.bounds.size.height* 0.5)];
    }
}

- (void)handlePinch:(UIPinchGestureRecognizer*)gesture {
    CGFloat sign = (gesture.velocity / fabs(gesture.velocity));
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            if ([self.delegate respondsToSelector:@selector(videoGestureLayer:BeginCameraZoom:)]) {
                [self.delegate videoGestureLayer:self
                                 BeginCameraZoom:gesture.scale * sign];
            }
            gesture.scale = 1;
            break;
        case UIGestureRecognizerStateChanged:
            if (!isnan(sign)) {
                if ([self.delegate respondsToSelector:@selector(videoGestureLayer:CameraZoomingWithDetalScale:)]) {
                    [self.delegate videoGestureLayer:self
                         CameraZoomingWithDetalScale:gesture.scale * sign];
                }
            }
            gesture.scale = 1;
            break;
        case UIGestureRecognizerStateEnded:
            if ([self.delegate respondsToSelector:@selector(videoGestureLayer:DidFinishCameraZoom:)]) {
                [self.delegate videoGestureLayer:self
                             DidFinishCameraZoom:gesture.scale * sign];
            }
            gesture.scale = 1;
            break;
        default:
            break;
    }
}

- (void)runTapWigetZoomAnimationTo:(CGPoint)point {
    [self.zoomAnimator stopAnimation:TRUE];
    [self.hiddenAnimator stopAnimation:TRUE];
    self.unvisibleWiget.layer.transform = CATransform3DIdentity;
    self.zoomAnimator = [[UIViewPropertyAnimator alloc] initWithDuration:0.2
                                                                   curve:UIViewAnimationCurveEaseInOut
                                                              animations:^{
                                                                  self.tapWiget.layer.transform = CATransform3DMakeScale(0.5, 0.5, 0.5);
                                                              }];
    
    
    __weak VideoGestureLayer* weakSelf = self;
    [self.zoomAnimator addCompletion:^(UIViewAnimatingPosition finalPosition) {
        if (finalPosition == UIViewAnimatingPositionEnd && weakSelf) {
            weakSelf.hiddenAnimator = [[UIViewPropertyAnimator alloc] initWithDuration:WIGET_DELAY_HIDE_TIME
                                                                                 curve:UIViewAnimationCurveLinear
                                                                            animations:^{
                                                                                if (weakSelf) {
                                                                                    weakSelf.unvisibleWiget.layer.transform = CATransform3DMakeScale(0.5, 0.5, 0.5);
                                                                                }
                                                                            }];
            [weakSelf.hiddenAnimator addCompletion:^(UIViewAnimatingPosition finalPosition) {
                if (finalPosition == UIViewAnimatingPositionEnd && weakSelf) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.tapWiget.hidden = TRUE;
                    });
                }
            }];
            
            [weakSelf.hiddenAnimator startAnimation];
        }
    }];
    
    self.tapWiget.center = point;
    self.tapWiget.layer.transform = CATransform3DIdentity;
    self.tapWiget.hidden = FALSE;
    
    [self.zoomAnimator startAnimation];
}

- (void)setTapToFocusAndExposureEnabled:(BOOL)tapToFocusAndExposureEnabled {
    self.singleTapGesture.enabled = tapToFocusAndExposureEnabled;
    self.doubleTapGesture.enabled = tapToFocusAndExposureEnabled;
}

- (BOOL)tapToFocusAndExposureEnabled {
    return self.singleTapGesture.enabled && self.doubleTapGesture.enabled;
}

- (void)setPinchToZoomCameraEnabled:(BOOL)pinchToZoomCameraEnabled {
    self.pinchGesture.enabled = pinchToZoomCameraEnabled;
}

- (BOOL)pinchToZoomCameraEnabled {
    return self.pinchGesture.enabled;
}


@end
