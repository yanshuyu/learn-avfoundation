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
@property (strong, nonatomic) UIPinchGestureRecognizer* pinchGesture;
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
    self.pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                  action:@selector(handlePinch:)];
    self.doubleTapGesture.numberOfTapsRequired = 2;
    [self.singleTapGesture requireGestureRecognizerToFail:self.doubleTapGesture];
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
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    return (AVCaptureVideoPreviewLayer*)self.layer;
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
    if ([self.delegate respondsToSelector:@selector(videoPreviewView:TapToFocusAndExposureAtPoint:)]) {
        [self.delegate videoPreviewView:self
           TapToFocusAndExposureAtPoint:deviceInterestPoint];
    }
}

- (void)handleDoubleTap:(UIGestureRecognizer*)gesture {
    [self runTapWigetZoomAnimationTo:self.center];
    if ([self.delegate respondsToSelector:@selector(videoPreviewView:TapToResetFocusAndExposure:)]) {
        [self.delegate videoPreviewView:self
             TapToResetFocusAndExposure:CGPointMake(0.5, 0.5)];
    }
}

- (void)handlePinch:(UIPinchGestureRecognizer*)gesture {
    CGFloat sign = (gesture.velocity / fabs(gesture.velocity));
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            if ([self.delegate respondsToSelector:@selector(videoPreviewView:BeginCameraZoom:)]) {
                [self.delegate videoPreviewView:self
                                BeginCameraZoom:gesture.scale * sign];
            }
            gesture.scale = 1;
            break;
        case UIGestureRecognizerStateChanged:
            if (!isnan(sign)) {
                if ([self.delegate respondsToSelector:@selector(videoPreviewView:CameraZooming:)]) {
                    [self.delegate videoPreviewView:self
                                      CameraZooming:gesture.scale * sign];
                }
            }
            gesture.scale = 1;
            break;
        case UIGestureRecognizerStateEnded:
            if ([self.delegate respondsToSelector:@selector(videoPreviewView:DidFinishCameraZoom:)]) {
                [self.delegate videoPreviewView:self
                            DidFinishCameraZoom:gesture.scale * sign];
            }
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
