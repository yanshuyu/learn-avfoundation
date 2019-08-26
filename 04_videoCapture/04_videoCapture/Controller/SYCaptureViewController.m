//
//  SYCaptureViewController.m
//  04_videoCapture
//
//  Created by sy on 2019/7/9.
//  Copyright © 2019 sy. All rights reserved.
//
#import "SYCaptureViewController.h"
#import "../View/VideoPreviewView.h"
#import "../View/VideoGestureLayer.h"
#import "../Controller/CaptureController.h"
#import "../Supported/ScrollableTabBar.h"
#import "../Supported/SYScrollableTabBarItem.h"
#import "../Supported/ContextManager.h"
#import "../Supported/BuildInFilterLibrary.h"
#import "../Supported/CameraRollManager.h"
#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface SYCaptureViewController () <CaptureControllerDelegate,
                                        ScrollableTabBarDelegate,
                                        VideoGestureLayerDelegate,
                                        UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet VideoPreviewView *videoPreviewView;
@property (weak, nonatomic) IBOutlet VideoGestureLayer *videoGestureView;
@property (weak, nonatomic) IBOutlet UIView *scrollableTabBarContainer;
@property (weak, nonatomic) IBOutlet UIStackView *zoomSliderContainer;
@property (weak, nonatomic) IBOutlet UIButton *captureButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraSwitchButton;
@property (weak, nonatomic) IBOutlet UIButton *albumButton;
@property (weak, nonatomic) IBOutlet UISlider *zoomSlider;
@property (weak, nonatomic) IBOutlet UIView *captureSettingContainerView;
@property (weak, nonatomic) IBOutlet UIView *photoSettingView;
@property (weak, nonatomic) IBOutlet UIButton *flashSwitchButton;
@property (weak, nonatomic) IBOutlet UIButton *livePhotoSwitchButton;
@property (weak, nonatomic) IBOutlet UIButton *hdrSwitchButton;
@property (weak, nonatomic) IBOutlet UIView *flashMeunView;
@property (weak, nonatomic) IBOutlet UIButton *flashAutoButton;
@property (weak, nonatomic) IBOutlet UIButton *flashOnButton;
@property (weak, nonatomic) IBOutlet UIButton *flashOffButton;
@property (weak, nonatomic) IBOutlet UILabel *liveLable;
@property (weak, nonatomic) IBOutlet UIView *framePreviewView;
@property (weak, nonatomic) IBOutlet UIImageView *framePreviewImage;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *blurEffectView;


@property (strong, nonatomic) CaptureController* captureController;
@property (strong, nonatomic) VideoGestureLayer* captureGestureLayer;
@property (strong, nonatomic) ScrollableTabBar* scrollableTabBar;
@property (nonatomic) CaptureMode currentCaptureMode;
@property (strong, nonatomic) UIViewPropertyAnimator* zoomSliderAnimator;
@property (strong, nonatomic) UIView*  zoomSliderAnimHelperWiget;
@property (strong, nonatomic) UIViewPropertyAnimator* blurEffectAnimator;
@property (nonatomic) int lastSelectedModeIndex;
@property (nonatomic) AVCaptureDevicePosition lastCameraPosition;

@end

@implementation SYCaptureViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpView];
    NSLog(@"video filters: %@", [[BuildInFilterLibrary shareInstance] filterNamesInCategory:kCICategoryStylize]);
    
    
    //setup capture mode switch view controller
    UIImageView* barItemSelectedIndicator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"select_indicator"]];
    barItemSelectedIndicator.frame = CGRectMake(0, 0, 12, 12);
    SYScrollableTabBarItem* photoBarItem = [[SYScrollableTabBarItem alloc] initWithTitleString:@"Photo" CaptureMode:CaptureModePhoto];
    SYScrollableTabBarItem* videoBarItem = [[SYScrollableTabBarItem alloc] initWithTitleString:@"Movie" CaptureMode:CaptureModeVideo];
    SYScrollableTabBarItem* filterVideoItem = [[SYScrollableTabBarItem alloc] initWithTitleString:@"Video" CaptureMode:CaptureModeRealTimeFilterVideo];
    NSArray<SYScrollableTabBarItem*>* barItems = [NSArray arrayWithObjects:photoBarItem, videoBarItem, filterVideoItem, nil];
    self.scrollableTabBar = [[ScrollableTabBar alloc] initWithFrame:self.scrollableTabBarContainer.bounds
                                                              Items:barItems
                                                          ItemSpace:5
                                              SelectedItemIndicator:barItemSelectedIndicator
                                                           Delegate:self];
    [self.scrollableTabBarContainer addSubview:self.scrollableTabBar];
    
    //setup capture session
    self.captureController = [CaptureController new];
    self.captureController.delegate = self;
    //[self.captureController setPreviewLayer:self.videoPreviewView.previewLayer];
    [self.captureController setupSessionWithCompletionHandle:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.captureController setPreviewLayer:self.videoPreviewView.previewLayer];
            [self.captureController startSession];
            [self.captureController switchToMode:barItems.firstObject.mode];
            [self syncZoomSliderWithDeviceZoomLevel];
            [self EnumerateCaptureDeviceCapbilites];
        });
    }];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.captureController startSession];
}

- (BOOL)shouldAutorotate {
    return FALSE;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)setUpView {
    self.scrollableTabBarContainer.backgroundColor = [UIColor blackColor];
    [self.captureButton setImage:[UIImage imageNamed:@"square"] forState:UIControlStateSelected];
    self.albumButton.layer.borderWidth = 1;
    self.albumButton.layer.borderColor = [UIColor redColor].CGColor;
    self.albumButton.layer.cornerRadius = 4;
    self.albumButton.layer.masksToBounds = true;
    self.liveLable.hidden = TRUE;
    
    self.zoomSliderContainer.alpha = 0;
    self.zoomSliderAnimHelperWiget = [UIView new];
    self.zoomSliderAnimHelperWiget.frame = CGRectMake(0, 0, 100, 100);
    self.zoomSliderAnimHelperWiget.hidden = TRUE;
    self.zoomSliderAnimHelperWiget.layer.borderWidth = 1;
    self.zoomSliderAnimHelperWiget.layer.borderColor = [UIColor.redColor CGColor];
    [self.view addSubview:self.zoomSliderAnimHelperWiget];
    
    self.videoPreviewView.layer.anchorPoint = CGPointMake(0, 0);
    self.videoGestureView.layer.anchorPoint = CGPointMake(0, 0);
    self.framePreviewImage.contentMode = UIViewContentModeScaleAspectFill;
    [self updatePreviewViewFrameForCaptureMode:CaptureModeVideo];
    
    self.videoGestureView.delegate = self;
    
    self.flashMeunView.alpha = 0;
    [self runFlashMenuFadeAnimation:FALSE];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.captureController cleanUpSession];
}

- (BOOL)prefersStatusBarHidden {
    return TRUE;
}

- (void)EnumerateCaptureDeviceCapbilites {
    BOOL tapToFocusAndExposureEnable = self.captureController.tapToFocusSupported && self.captureController.tapToExposureSupported;
    //self.videoPreviewView.tapToFocusAndExposureEnabled = tapToFocusAndExposureEnable;
    self.videoGestureView.tapToFocusAndExposureEnabled = tapToFocusAndExposureEnable;
    self.captureController.tapToFocusEnabled = tapToFocusAndExposureEnable;
    self.captureController.tapToExposureEnabled = tapToFocusAndExposureEnable;

    //self.videoPreviewView.pinchToZoomCameraEnabled = self.captureController.cameraZoomSupported;
    self.videoGestureView.pinchToZoomCameraEnabled = self.captureController.cameraZoomSupported;
    self.captureController.cameraZoomEnabled = self.captureController.cameraZoomSupported;
    
    self.cameraSwitchButton.hidden = !self.captureController.switchCameraSupported;
    self.captureController.switchCameraEnabled = self.captureController.switchCameraSupported;
    
    self.flashSwitchButton.hidden = !self.captureController.flashModeSwitchSupported;
    self.captureController.flashModeSwitchEnabled = self.captureController.flashModeSwitchSupported;
    self.flashSwitchButton.enabled = self.captureController.flashModeSwitchEnabled;
    
    self.livePhotoSwitchButton.hidden = !self.captureController.livePhotoCaptureSupported;
    self.captureController.livePhotoCaptureEnabled = self.captureController.livePhotoCaptureSupported;
    self.livePhotoSwitchButton.enabled = self.captureController.livePhotoCaptureEnabled;
}

- (void)syncZoomSliderWithDeviceZoomLevel {
    float percent = (self.captureController.cameraZoomFactor - self.captureController.cameraMinZoomFactor) / (self.captureController.cameraMaxZoomFactor - self.captureController.cameraMinZoomFactor);
    [self.zoomSlider setValue:percent animated:FALSE];
}

- (void)updatePhotoCaptureSettingView {
   // if (!self.flashSwitchButton.hidden) {
        self.flashAutoButton.titleLabel.textColor = UIColor.whiteColor;
        self.flashOnButton.titleLabel.textColor = UIColor.whiteColor;
        self.flashOffButton.titleLabel.textColor = UIColor.whiteColor;
        
        NSString* flashStateImage = @"";
        if (self.captureController.flashMode == AVCaptureFlashModeOff) {
            flashStateImage = @"flash_off";
            self.flashOffButton.titleLabel.textColor = UIColor.redColor;
        } else if (self.captureController.flashMode == AVCaptureFlashModeOn) {
            flashStateImage = @"flash_on";
            self.flashOnButton.titleLabel.textColor = UIColor.redColor;
        } else if (self.captureController.flashMode == AVCaptureFlashModeAuto) {
            flashStateImage = @"flash_auto";
            self.flashAutoButton.titleLabel.textColor = UIColor.redColor;
        }
        [self.flashSwitchButton setImage:[UIImage imageNamed:flashStateImage]
                                forState:UIControlStateNormal];
        
  //  }
}

- (void)updatePreviewViewFrameForCaptureMode:(CaptureMode)mode {
    if (mode == CaptureModePhoto) {
        CGPoint position = CGPointMake(self.photoSettingView.frame.origin.x, self.photoSettingView.frame.origin.y + self.photoSettingView.frame.size.height);
        [UIView animateWithDuration:0.25
                         animations:^{
            self.videoPreviewView.frame = CGRectMake(0, 0, self.view.bounds.size.width,
                                                     self.view.bounds.size.height  - self.scrollableTabBarContainer.frame.size.height - self.captureSettingContainerView.frame.size.height);
            self.videoPreviewView.center = position;
        }
                         completion:^(BOOL finished) {
                             self.videoGestureView.frame = self.videoPreviewView.frame;
                             NSLog(@"preview layer rectect:[x=%f, y=%f, w=%f, h=%f]", self.videoPreviewView.frame.origin.x, self.videoPreviewView.frame.origin.y, self.videoPreviewView.frame.size.width, self.videoPreviewView.frame.size.height);
                             
                         }];
    } else if (mode == CaptureModeVideo || mode == CaptureModeRealTimeFilterVideo) {
        [UIView animateWithDuration:0.25
                         animations:^{
            self.videoPreviewView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
            self.videoPreviewView.center =  CGPointMake(0, 0);
        }
                         completion:^(BOOL finished) {
                             self.videoPreviewView.frame = self.videoPreviewView.frame;
                             NSLog(@"preview layer Rectect:[x=%f, y=%f, w=%f, h=%f]", self.videoPreviewView.frame.origin.x, self.videoPreviewView.frame.origin.y, self.videoPreviewView.frame.size.width, self.videoPreviewView.frame.size.height);
                             
                         }];
    }
    
}

- (void)runZoomSliderFadeAnimaton:(BOOL)visible {
    if (visible) {
        [self.zoomSliderAnimator stopAnimation: TRUE];
        self.zoomSliderAnimator = Nil;
        [UIView animateWithDuration:0.25
                         animations:^{
                             self.zoomSliderContainer.alpha = 1;
                         } completion:^(BOOL finished) {
                             NSLog(@"show zoom slider");
                         }];
    } else {
        self.zoomSliderAnimator = [[UIViewPropertyAnimator alloc] initWithDuration:2
                                                                             curve:UIViewAnimationCurveEaseInOut
                                                                        animations:^{
                                                                            self.zoomSliderAnimHelperWiget.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
                                                                        }];
        __weak SYCaptureViewController* weakSelf = self;
        [self.zoomSliderAnimator addCompletion:^(UIViewAnimatingPosition finalPosition) {
            if (finalPosition == UIViewAnimatingPositionEnd) {
                [UIView animateWithDuration:0.25
                                 animations:^{
                                     weakSelf.zoomSliderContainer.alpha = 0;
                                 } completion:^(BOOL finished) {
                                     NSLog(@"hide zoom slider");
                                 }];
            }
        }];
        self.zoomSliderAnimHelperWiget.transform = CGAffineTransformIdentity;
        [self.zoomSliderAnimator startAnimation];
    }
}

- (void)runFlashMenuFadeAnimation:(BOOL)visible {
    if (visible && self.flashMeunView.hidden) {
        self.flashMeunView.hidden = FALSE;
        self.flashMeunView.alpha = 0;
        CGPoint targetCenter = self.captureSettingContainerView.center;
        targetCenter.y = self.captureSettingContainerView.bounds.size.height + self.flashMeunView.bounds.size.height * 0.5;
        [UIView animateWithDuration:0.25
                         animations:^{
                             self.flashMeunView.center = targetCenter;
                             self.flashMeunView.alpha = 1;
                         }];
    }
    
    if (!visible && !self.flashMeunView.hidden) {
        CGPoint targetCenter = self.captureSettingContainerView.center;
        targetCenter.y = self.captureSettingContainerView.bounds.size.height - self.flashMeunView.bounds.size.height;
        [UIView animateWithDuration:0.25
                         animations:^{
                             self.flashMeunView.center = targetCenter;
                             self.flashMeunView.alpha = 0;
                         }
                         completion:^(BOOL finished) {
                             [self updatePhotoCaptureSettingView];
                             self.flashMeunView.hidden = TRUE;
                         }];
    }
}


- (IBAction)handleCaptureButtonTap:(UIButton *)sender {
    if (self.currentCaptureMode == CaptureModePhoto) {
        [self.captureController capturePhoto];
    }
    
    if (self.currentCaptureMode == CaptureModeVideo || self.currentCaptureMode == CaptureModeRealTimeFilterVideo) {
        if (self.captureController.recording) {
            [self.captureController stopRecording];
        } else {
            [self.captureController startRecording];
        }
    }
}

- (IBAction)handleSwitchCameraTap:(UIButton *)sender {
    [self.captureController switchCamera];
}

- (IBAction)handleZoomSliderTouchDragEnter:(UISlider *)sender {
    [self runZoomSliderFadeAnimaton:TRUE];
}

- (IBAction)handleZoomSliderTouchDraging:(UISlider *)sender {
    [self.captureController setVideoZoomWithPercent:sender.value];
}

- (IBAction)handleZoomSliderTouchDragExit:(UISlider *)sender {
    [self runZoomSliderFadeAnimaton:FALSE];
}

- (IBAction)handleZoomInButtonTouchDown:(UIButton *)sender {
    [self.captureController smoothZoomVideoTo:self.captureController.cameraMaxZoomFactor WithRate:2];
    [self runZoomSliderFadeAnimaton:TRUE];
}

- (IBAction)handleZoomInButtonTouchUp:(UIButton *)sender {
    [self.captureController cancelVideoSmoothZoom];
    [self runZoomSliderFadeAnimaton:FALSE];
}


- (IBAction)handleZoomOutButtonTouchDown:(UIButton *)sender {
    [self.captureController smoothZoomVideoTo:self.captureController.cameraMinZoomFactor WithRate:2];
    [self runZoomSliderFadeAnimaton:TRUE];
}

- (IBAction)handleZoomOutButtonTouchUp:(UIButton *)sender {
    [self.captureController cancelVideoSmoothZoom];
    [self runZoomSliderFadeAnimaton:FALSE];
}

- (IBAction)handleFlashSwitchButtonTap:(UIButton *)sender {
    NSLog(@"toggle flash mode");
    [self runFlashMenuFadeAnimation:self.flashMeunView.hidden];

}

- (IBAction)handleLivePhotoSwitchButtonTap:(UIButton *)sender {
    NSLog(@"toggle live photo mode");
    self.captureController.livePhotoMode = self.captureController.livePhotoMode == LivePhotoModeOn ? LivePhotoModeOff : LivePhotoModeOn;
}

- (IBAction)handleDHRSwitchButtonTap:(UIButton *)sender {
    NSLog(@"toggle dhr mode");
}

- (IBAction)handleFlashAutoButtonTap:(UIButton *)sender {
    if (self.captureController.flashMode != AVCaptureFlashModeAuto) {
        [self.captureController switchFlashMoe:AVCaptureFlashModeAuto];
    } else {
        [self runFlashMenuFadeAnimation:FALSE];
    }
}

- (IBAction)handleFlashOnButtonTap:(UIButton *)sender {
   // [self runFlashMenuFadeAnimation:FALSE];
    if (self.captureController.flashMode != AVCaptureFlashModeOn) {
        [self.captureController switchFlashMoe:AVCaptureFlashModeOn];
    } else {
        [self runFlashMenuFadeAnimation:FALSE];
    }
}

- (IBAction)handleFlashModeOffTap:(UIButton *)sender {
    //[self runFlashMenuFadeAnimation:FALSE];
    if (self.captureController.flashMode != AVCaptureFlashModeOff) {
        [self.captureController switchFlashMoe:AVCaptureFlashModeOff];
    } else {
        [self runFlashMenuFadeAnimation:FALSE];
    }
}

//
// MARK: - scrollable tab bar delegate
//
- (void)scrollableTabBar:(ScrollableTabBar *)bar beginUserScrollingFromSelectedIndex:(int)index {
    self.lastSelectedModeIndex = index;
    self.blurEffectAnimator = [[UIViewPropertyAnimator alloc] initWithDuration:0.5
                                                                         curve:UIViewAnimationCurveLinear
                                                                    animations:^{
                                                                        self.blurEffectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
                                                                    }];
    [self.blurEffectAnimator pauseAnimation];
}

- (void)scrollableTabBar:(ScrollableTabBar *)bar userScrollingWithSelectedItemOffset:(float)xoffset complectionPercent:(float)percent {
    [self.blurEffectAnimator setFractionComplete:percent];
}

- (void)scrollableTabBar:(ScrollableTabBar *)bar SelectItem:(ScrollableTabBarItem *)item AtIndex:(int)index {
    [self.captureController switchToMode:((SYScrollableTabBarItem*)item).mode];
}

- (void)scrollableTabBar:(ScrollableTabBar *)bar DeselectItem:(ScrollableTabBarItem *)item AtIndex:(int)index {
    
}

- (void)scrollableTabBar:(ScrollableTabBar *)bar finishUserScrollingToSelectedIndex:(int)index {
    [self.blurEffectAnimator stopAnimation:TRUE];
    if (index == self.lastSelectedModeIndex) {
        [UIView animateWithDuration:0.5 animations:^{
            self.blurEffectView.effect = Nil;
        }];
    }
}


//
// MARK: - capture gesture delegate
//
- (void)videoGestureLayer:(VideoGestureLayer *)layer TapToFocusAndExposureAtLayerPoint:(CGPoint)point {
    CGPoint pointAtPreviewLayer = [layer convertPoint:point toView:self.videoPreviewView];
    CGPoint pointAtDeviceSpace = [self.videoPreviewView.previewLayer captureDevicePointOfInterestForPoint:pointAtPreviewLayer];
    [self.captureController tapToFocusAtInterestPoint:pointAtDeviceSpace];
    [self.captureController tapToExposureAtInterestPoint:pointAtDeviceSpace];
    if (!self.flashMeunView.hidden) {
        [self runFlashMenuFadeAnimation:FALSE];
    }
}

- (void)videoGestureLayer:(VideoGestureLayer *)layer
TapToResetFocusAndExposureAtLayerPoint:(CGPoint)tapPoint
         RecommandedPoint:(CGPoint)recommandedpoint {
    [self.captureController resetFocus];
    [self.captureController resetExposure];
    if (!self.flashMeunView.hidden) {
        [self runFlashMenuFadeAnimation:FALSE];
    }
}

- (void)videoGestureLayer:(VideoGestureLayer *)layer BeginCameraZoom:(CGFloat)scale {
    [self runZoomSliderFadeAnimaton:TRUE];
    if (!self.flashMeunView.hidden) {
        [self runFlashMenuFadeAnimation:FALSE];
    }
}

- (void)videoGestureLayer:(VideoGestureLayer *)layer CameraZoomingWithDetalScale:(CGFloat)scale {
    CGFloat currentZoomFactor = self.captureController.cameraZoomFactor;
    [self.captureController setVideoZoomWithFactor:(currentZoomFactor + scale * 0.1)];
}


- (void)videoGestureLayer:(VideoGestureLayer *)layer DidFinishCameraZoom:(CGFloat)scale {
    [self runZoomSliderFadeAnimaton:FALSE];
}

//
// MARK: - image picker delegate
//
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [self.captureController startSession];
    [self dismissViewControllerAnimated:TRUE completion:Nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self.captureController startSession];
    [self dismissViewControllerAnimated:TRUE completion:Nil];
}

//
// MARK: - capture controller delegate
//
- (void)captureController:(CaptureController *)controller ConfigureSessionResult:(SessionConfigResult)result Error:(NSError *)error {
    if (result == SessionConfigResultUnAuthorized) {
        NSLog(@"config seesion failed, no authorization to capture device.");
    } else if (error) {
        NSLog(@"config session failed, error: %@", error.localizedDescription);
    }
}

- (void)captureControllerSessionDidStartRunning:(CaptureController *)controller {
    NSLog(@"capture sesession did start running.");
}

- (void)captureController:(CaptureController *)controller SessionDidStopRunning:(NSDictionary *)info {
    NSLog(@"capture session did stop running, info: %@", info);
}

- (void)captureControllerStartRunningSessionFailed:(CaptureController *)controller {
    NSLog(@"capture session start running failed!");
}

- (void)captureController:(CaptureController *)controller LeaveCaptureMode:(CaptureMode)mode {
    NSLog(@"Leave capture mode: %lu", (unsigned long)mode);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.cameraSwitchButton.userInteractionEnabled = FALSE;
        self.captureButton.userInteractionEnabled = FALSE;
        self.albumButton.userInteractionEnabled = FALSE;
        if (mode == CaptureModePhoto) {
            if (!self.flashMeunView.hidden) {
                [self runFlashMenuFadeAnimation:FALSE];
            }
            self.liveLable.hidden = TRUE;
        }
    });
}

- (void)captureController:(CaptureController *)controller EnterCaptureMode:(CaptureMode)mode {
    NSLog(@"Enter capture mode: %lu", (unsigned long)mode);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentCaptureMode = mode;
        self.cameraSwitchButton.userInteractionEnabled = TRUE;
        self.captureButton.userInteractionEnabled = TRUE;
        self.albumButton.userInteractionEnabled = TRUE;
        self.videoGestureView.tapToFocusAndExposureEnabled = self.captureController.tapToFocusEnabled && self.captureController.tapToExposureEnabled;
        self.videoGestureView.pinchToZoomCameraEnabled = self.captureController.cameraZoomEnabled;
        [self updatePreviewViewFrameForCaptureMode:mode];
        self.framePreviewView.hidden = (mode != CaptureModeRealTimeFilterVideo);
        //self.videoPreviewView.hidden = !self.framePreviewView.hidden;
        [UIView animateWithDuration:0.7 animations:^{
            self.blurEffectView.effect = Nil;
        }];
        if (self.currentCaptureMode == CaptureModePhoto) {
            UIImage* whiteCircle = [UIImage imageNamed:@"circle_white"];
            [self.captureButton setImage:whiteCircle forState:UIControlStateNormal];
            [self.scrollableTabBarContainer setBackgroundColor:[UIColor colorWithWhite:0 alpha:1]];
            [self.captureSettingContainerView setBackgroundColor:[UIColor colorWithWhite:0 alpha:1]];
            self.photoSettingView.hidden = FALSE;
            self.flashSwitchButton.hidden = !(self.captureController.flashModeSwitchSupported && self.captureController.flashModeSwitchEnabled);
            self.liveLable.hidden = !(self.captureController.livePhotoMode == LivePhotoModeOn);
            [self updatePhotoCaptureSettingView];

         
        } else if (self.currentCaptureMode == CaptureModeVideo || self.currentCaptureMode == CaptureModeRealTimeFilterVideo) {
            UIImage* redCircle = [UIImage imageNamed:@"circle_red"];
            [self.captureButton setImage:redCircle forState:UIControlStateNormal];
            [self.scrollableTabBarContainer setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
            [self.captureSettingContainerView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
            self.photoSettingView.hidden = TRUE;
       }
    });
}


- (void)captureController:(CaptureController *)controller BeginSwitchCameraFromPosition:(AVCaptureDevicePosition)position {
    self.lastCameraPosition = position;
    self.scrollableTabBar.interactionEnabled = FALSE;
}

- (void)captureController:(CaptureController *)controller FinishSwitchCameraToPosition:(AVCaptureDevicePosition)position Success:(BOOL)success {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (success) {
            self.scrollableTabBar.interactionEnabled = TRUE;
            UIViewAnimationOptions option = self.lastCameraPosition == AVCaptureDevicePositionFront ? UIViewAnimationOptionTransitionFlipFromRight : UIViewAnimationOptionTransitionFlipFromLeft;
            UIView* previewView = self.currentCaptureMode == CaptureModeRealTimeFilterVideo ? self.framePreviewView : self.videoPreviewView;
            if (self.lastCameraPosition != position && success) {
                [UIView transitionWithView:previewView
                                  duration:0.5
                                   options:option
                                animations:^{
                                    [UIView animateWithDuration:0.25 animations:^{
                                        self.blurEffectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
                                    } completion:^(BOOL finished) {
                                        [UIView animateWithDuration:0.5 animations:^{
                                            self.blurEffectView.effect = Nil;
                                        }];
                                    }];
                                }
                                completion:Nil];
            }
        }
    });
}

- (void)captureController:(CaptureController *)controller
SaveCapturePhotoWithSessionID:(int64_t)Id
      ToLibraryWithResult:(AssetSavedResult)result
                    Error:(NSError *)error {
    if (result == AssetSavedResultUnAuthorized) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Save Error"
                                                                                     message:@"please go to settings > videoCapture > Photos to allow we access to photo library to save your content"
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"ok"
                                                                style:UIAlertActionStyleDefault
                                                              handler:nil]];
            [self presentViewController:alertController animated:TRUE completion:nil];
        });
    }
}

- (void)captureController:(CaptureController *)controller DidStartRecordingToFileURL:(NSURL *)url {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.scrollableTabBar.interactionEnabled = FALSE;
        self.cameraSwitchButton.enabled = FALSE;
        self.albumButton.enabled = FALSE;
        [self.captureButton setSelected:TRUE];
    });
}

- (void)captureController:(CaptureController *)controller DidFinishRecordingToFileURL:(NSURL *)url Error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.scrollableTabBar.interactionEnabled = TRUE;
        self.cameraSwitchButton.enabled = TRUE;
        self.albumButton.enabled = TRUE;
        [self.captureButton setSelected:FALSE];
    });
}

- (void)captureController:(CaptureController *)controller BeginRealTimeFilterVideoRecordSession:(BOOL)ready {
    if (ready) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.scrollableTabBar.interactionEnabled = FALSE;
            self.cameraSwitchButton.enabled = FALSE;
            self.albumButton.enabled = FALSE;
            [self.captureButton setSelected:TRUE];
        });
    }
}

- (void)captureController:(CaptureController *)controller
FinishRealTimeFilterVideoRecordSessionWithOutputURL:(NSURL *)url
                    Error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.scrollableTabBar.interactionEnabled = TRUE;
        self.cameraSwitchButton.enabled = TRUE;
        self.albumButton.enabled = TRUE;
        [self.captureButton setSelected:FALSE];
    });
}

- (CIImage *)captureController:(CaptureController *)controller ExpectedProcessingFilterVideoFrame:(CIImage *)frame {
    CIFilter* filter = [CIFilter filterWithName:@"CIComicEffect"];
    CIImage* processImage = Nil;
    if (filter) {
        [filter setValue:frame forKey:kCIInputImageKey];
        processImage = filter.outputImage;
    }
    
    processImage = processImage == Nil ? frame : processImage;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.framePreviewImage.image = [UIImage imageWithCIImage:processImage];
    });
    
    return processImage;
}

- (void)captureController:(CaptureController *)controller DidCameraZoomToFactor:(CGFloat)factor {
    dispatch_async(dispatch_get_main_queue(), ^{
        //NSLog(@"camera zoom factor: %f", factor);
        [self syncZoomSliderWithDeviceZoomLevel];
    });
}

- (void)captureController:(CaptureController *)controller DidSwitchFlashModeTo:(AVCaptureFlashMode)mode {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self runFlashMenuFadeAnimation:FALSE];
    });
}

- (void)captureController:(CaptureController *)controller DidToggleLivePhotoModeTo:(LivePhotoMode)mode {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.livePhotoSwitchButton.hidden) {
            NSString* liveModeImageName = mode == LivePhotoModeOn ? @"live_on" : @"live_off";
            [self.livePhotoSwitchButton setImage:[UIImage imageNamed:liveModeImageName]
                                        forState:UIControlStateNormal];
            self.liveLable.hidden = !(mode == LivePhotoModeOn);
        }
    });
}

//- (void)captureController:(CaptureController *)controller DidCaptureVideoFrame:(CIImage *)image {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if (!self.ciContext) {
//            self.ciContext = [CIContext new];
//        }
//        //UIImage* content = [UIImage imageWithCIImage:image];
//        CGImageRef cgImage = [self.ciContext createCGImage:image fromRect:image.extent];
//        if (cgImage) {
//            self.framePreviewImage.image = [UIImage imageWithCGImage:cgImage];
//            CGImageRelease(cgImage);
//        }
//    });
//}

@end
