//
//  SYVideoPreviewView.m
//  04_videoCapture
//
//  Created by sy on 2019/7/9.
//  Copyright © 2019 sy. All rights reserved.
//

#import "VideoPreviewView.h"
#import "FocusWiget.h"

#define WIGET_SIZE CGRectMake(0, 0, 120, 120)
#define WIGET_COLOR [UIColor colorWithRed:255 green:0 blue:0 alpha:1]
#define WIGET_DELAY_HIDE_TIME 0.8

@interface VideoPreviewView ()

@property (strong, nonatomic) UITapGestureRecognizer* singleTapGesture;
@property (strong, nonatomic) UITapGestureRecognizer* doubleTapGesture;
@property (strong, nonatomic) FocusWiget* tapWiget;
@property (strong, nonatomic) FocusWiget* unvisibleWiget;
@property (strong, nonatomic) UIViewPropertyAnimator* zoomAnimator;
@property (strong, nonatomic) UIViewPropertyAnimator* hiddenAnimator;

@end





@implementation VideoPreviewView

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

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (void)setupView {
    self.backgroundColor = [UIColor blackColor];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    self.singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(hanleSingleTap:)];
    self.doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(handleDoubleTap:)];
    self.doubleTapGesture.numberOfTapsRequired = 2;
    [self.singleTapGesture requireGestureRecognizerToFail:self.doubleTapGesture];
    [self addGestureRecognizer:self.singleTapGesture];
    [self addGestureRecognizer:self.doubleTapGesture];
    
    
    self.tapWiget = [[FocusWiget alloc] initWithFrame:WIGET_SIZE color:WIGET_COLOR];
    self.tapWiget.hidden = TRUE;
    [self addSubview:self.tapWiget];
    
    self.unvisibleWiget = [[FocusWiget alloc] initWithFrame:WIGET_SIZE color:WIGET_COLOR];
    self.unvisibleWiget.hidden = TRUE;
    [self addSubview:self.unvisibleWiget];
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    return (AVCaptureVideoPreviewLayer*)self.layer;
}


- (void)setCaptureSession:(AVCaptureSession *)captureSession {
    self.previewLayer.session = captureSession;
}

- (AVCaptureSession *)captureSession {
    return self.previewLayer.session;
}

- (void)hanleSingleTap:(UIGestureRecognizer*)gesture {
    CGPoint point = [gesture locationInView:self];
    CGPoint deviceInterestPoint = [self.previewLayer captureDevicePointOfInterestForPoint:point];
    [self runTapWigetZoomAnimationTo:point];
    [self.delegate tapToFocusAndExposureAtPoint:deviceInterestPoint];
}

- (void)handleDoubleTap:(UIGestureRecognizer*)gesture {
    [self runTapWigetZoomAnimationTo:self.center];
    [self.delegate tapToResetFocusAndExposure];
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
    
    
    __weak VideoPreviewView* weakSelf = self;
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

@end
