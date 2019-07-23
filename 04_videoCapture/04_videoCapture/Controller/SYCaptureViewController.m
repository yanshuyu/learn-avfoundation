//
//  SYCaptureViewController.m
//  04_videoCapture
//
//  Created by sy on 2019/7/9.
//  Copyright © 2019 sy. All rights reserved.
//
#import <MobileCoreServices/MobileCoreServices.h>
#import "SYCaptureViewController.h"
#import "../View/VideoPreviewView.h"
#import "../Controller/CaptureController.h"
#import "../Supported/ScrollableTabBar.h"
#import "../Supported/SYScrollableTabBarItem.h"
#import <Photos/Photos.h>

@interface SYCaptureViewController () <CaptureControllerDelegate, ScrollableTabBarDelegate, VideoPreviewViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet VideoPreviewView *videoPreviewView;
@property (weak, nonatomic) IBOutlet UIView *scrollableTabBarContainer;
@property (weak, nonatomic) IBOutlet UIStackView *zoomSliderContainer;
@property (weak, nonatomic) IBOutlet UIButton *captureButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraSwitchButton;
@property (weak, nonatomic) IBOutlet UIButton *albumButton;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *blurEffectView;
@property (weak, nonatomic) IBOutlet UISlider *zoomSlider;


@property (strong, nonatomic) CaptureController* captureController;
@property (strong, nonatomic) ScrollableTabBar* scrollableTabBar;
@property (nonatomic) CaptureMode currentCaptureMode;
@property (strong, nonatomic) UIViewPropertyAnimator* zoomSliderAnimator;

@end

@implementation SYCaptureViewController


- (void)viewDidLoad {
    [super viewDidLoad];

    //setup scrollable tab bar
    self.zoomSliderContainer.alpha = 0;
    UIImageView* barItemSelectedIndicator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"select_indicator"]];
    barItemSelectedIndicator.frame = CGRectMake(0, 0, 12, 12);
    SYScrollableTabBarItem* photoBarItem = [[SYScrollableTabBarItem alloc] initWithTitleString:@"Photo" CaptureMode:CaptureModePhoto];
    SYScrollableTabBarItem* videoBarItem = [[SYScrollableTabBarItem alloc] initWithTitleString:@"Video" CaptureMode:CaptureModeVideo];
    NSArray<SYScrollableTabBarItem*>* barItems = [NSArray arrayWithObjects:photoBarItem, videoBarItem, nil];
    self.scrollableTabBar = [[ScrollableTabBar alloc] initWithFrame:self.scrollableTabBarContainer.bounds
                                                              Items:barItems
                                                          ItemSpace:5
                                              SelectedItemIndicator:barItemSelectedIndicator
                                                           Delegate:self];
    [self.scrollableTabBarContainer addSubview:self.scrollableTabBar];
   
    self.videoPreviewView.delegate = self;
    
    //setup capture session
    self.captureController = [CaptureController new];
    self.captureController.delegate = self;
    [self.captureController setPreviewLayer:self.videoPreviewView.previewLayer];
    [self.captureController setupSessionWithCompletionHandle:^{
        [self.captureController switchToMode:barItems.firstObject.mode];
        
        // enable or disable tap to focus and exposure
        BOOL tapToFocusAndExposureEnable = self.captureController.tapToFocusSupported && self.captureController.tapToExposureSupported;
        self.videoPreviewView.tapToFocusAndExposureEnabled = tapToFocusAndExposureEnable;
        self.captureController.tapToFocusEnabled = tapToFocusAndExposureEnable;
        self.captureController.tapToExposureEnabled = tapToFocusAndExposureEnable;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupView];
        });
    }];

}

- (void)viewWillDisappear:(BOOL)animated {
    [self.captureController cleanUpSession];
}

- (BOOL)prefersStatusBarHidden {
    return TRUE;
}

- (void)setupView {
    self.scrollableTabBarContainer.backgroundColor = [UIColor blackColor];
    [self.captureButton setImage:[UIImage imageNamed:@"square"] forState:UIControlStateSelected];
    self.blurEffectView.hidden = TRUE;
    self.albumButton.layer.borderWidth = 1;
    self.albumButton.layer.borderColor = [UIColor redColor].CGColor;
    self.albumButton.layer.cornerRadius = 4;
    self.albumButton.layer.masksToBounds = true;
    
    self.cameraSwitchButton.hidden = !self.captureController.switchCameraSupported;
    self.videoPreviewView.tapToFocusAndExposureEnabled = self.captureController.tapToFocusSupported && self.captureController.tapToExposureSupported;
    self.videoPreviewView.pinchToZoomCameraEnabled = self.captureController.cameraZoomSupported;
    
    [self syncZoomSliderWithDeviceZoomLevel];
}


- (void)runZoomSliderFadeAnimaton:(BOOL)visible {
    [self.zoomSliderAnimator stopAnimation:TRUE];
    if (visible) {
        self.zoomSliderAnimator = [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:0.25
                                                                                        delay:0
                                                                                      options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                                                                                   animations:^{
                                                                                       self.zoomSliderContainer.alpha = 1;
                                                                                   }
                                                                                   completion:^(UIViewAnimatingPosition finalPosition) {
                                                                                       if (finalPosition == UIViewAnimatingPositionEnd) {
                                                                                           NSLog(@"zoom slider hidden: 0");
                                                                                       }
                                                                                   }];
        
    } else {
        self.zoomSliderAnimator = [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:0.5
                                                                                        delay:3
                                                                                      options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                                                                                   animations:^{
                                                                                       self.zoomSliderContainer.alpha = 0;
                                                                                   }
                                                                                   completion:^(UIViewAnimatingPosition finalPosition) {
                                                                                       if (finalPosition == UIViewAnimatingPositionEnd) {
                                                                                           NSLog(@"zoom slider hidden: 1");
                                                                                       }
                                                                                   }];
    }
}


- (IBAction)handleCaptureButtonTap:(UIButton *)sender {
    if (self.currentCaptureMode == CaptureModePhoto) {
        [self.captureController capturePhoto];
    }
    
    if (self.currentCaptureMode == CaptureModeVideo) {
        if (self.captureController.recording) {
            [self.captureController stopRecording];
        } else {
            [self.captureController startRecording];
        }
    }
}

- (IBAction)handleSwitchCameraTap:(UIButton *)sender {
    NSLog(@"switch camera tapping");
    [self.captureController switchCamera];
}

- (IBAction)handleAlbumButtonTap:(UIButton *)sender {
    NSLog(@"album button tapped");

    void(^presentPhotoViewer)(void) = ^{
        UIImagePickerController* imagePickerController = [UIImagePickerController new];
        imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        imagePickerController.mediaTypes = @[(NSString*)kUTTypeImage, (NSString*)kUTTypeVideo];
        imagePickerController.allowsEditing = FALSE;
        imagePickerController.delegate = self;
        [self presentViewController:imagePickerController animated:TRUE completion:Nil];
    };
    
    PHAuthorizationStatus photoLibraryAuthorization = [PHPhotoLibrary authorizationStatus];
    if (photoLibraryAuthorization == PHAuthorizationStatusDenied || photoLibraryAuthorization == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    presentPhotoViewer();
                });
            }
        }];
        return ;
    }
    presentPhotoViewer();
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


//
// MARK: - scrollable tab bar delegate
//
- (void)scrollableTabBar:(ScrollableTabBar *)bar SelectItem:(ScrollableTabBarItem *)item AtIndex:(int)index {
    [self.captureController switchToMode:((SYScrollableTabBarItem*)item).mode];
}

- (void)scrollableTabBar:(ScrollableTabBar *)bar DeselectItem:(ScrollableTabBarItem *)item AtIndex:(int)index {
    
}


//
// MARK: - videoPreview delegate
//
- (void)syncZoomSliderWithDeviceZoomLevel {
    float percent = (self.captureController.cameraZoomFactor - self.captureController.cameraMinZoomFactor) / (self.captureController.cameraMaxZoomFactor - self.captureController.cameraMinZoomFactor);
    [self.zoomSlider setValue:percent animated:FALSE];
}

- (void)videoPreviewView:(VideoPreviewView *)view TapToFocusAndExposureAtPoint:(CGPoint)point {
    [self.captureController tapToFocusAtInterestPoint:point];
    [self.captureController tapToExposureAtInterestPoint:point];
}

- (void)videoPreviewView:(VideoPreviewView *)view TapToResetFocusAndExposure:(CGPoint)point {
    [self.captureController resetFocus];
    [self.captureController resetExposure];
}

- (void)videoPreviewView:(VideoPreviewView *)view BeginCameraZoom:(CGFloat)scale {
    [self runZoomSliderFadeAnimaton:TRUE];
}

- (void)videoPreviewView:(VideoPreviewView *)view CameraZooming:(CGFloat)scale {
    CGFloat currentZoomFactor = self.captureController.cameraZoomFactor;
    [self.captureController setVideoZoomWithFactor:(currentZoomFactor + scale * 0.1)];
    //[self syncZoomSliderWithDeviceZoomLevel];
}

- (void)videoPreviewView:(VideoPreviewView *)view DidFinishCameraZoom:(CGFloat)scale {
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

- (void)captureControllerSessionDidStopRunning:(CaptureController *)controller {
    NSLog(@"capture session did stop running.");
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
        self.blurEffectView.hidden = FALSE;
    });
}

- (void)captureController:(CaptureController *)controller EnterCaptureMode:(CaptureMode)mode {
    NSLog(@"Enter capture mode: %lu", (unsigned long)mode);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentCaptureMode = mode;
        self.cameraSwitchButton.userInteractionEnabled = TRUE;
        self.captureButton.userInteractionEnabled = TRUE;
        self.albumButton.userInteractionEnabled = TRUE;
        self.blurEffectView.hidden = TRUE;
        
        if (self.currentCaptureMode == CaptureModePhoto) {
            self.scrollableTabBar.interactionEnabled = self.captureController.tapToFocusEnabled && self.captureController.tapToExposureEnabled;
            UIImage* whiteCircle = [UIImage imageNamed:@"circle_white"];
            [self.captureButton setImage:whiteCircle forState:UIControlStateNormal];
            self.scrollableTabBarContainer.alpha = 1;
         
        } else if (self.currentCaptureMode == CaptureModeVideo) {
            self.scrollableTabBar.interactionEnabled = self.captureController.tapToFocusEnabled && self.captureController.tapToExposureEnabled;
            UIImage* redCircle = [UIImage imageNamed:@"circle_red"];
            [self.captureButton setImage:redCircle forState:UIControlStateNormal];
            self.scrollableTabBarContainer.alpha = 0.5;
       }
    });
}

- (void)captureControllerBeginSwitchCamera {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.blurEffectView.hidden = FALSE;
    });
}

- (void)captureControllerDidFinishSwitchCamera:(BOOL)success {
    NSLog(@"camera switch: %d", success);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.blurEffectView.hidden = TRUE;
        if (success) {
            self.scrollableTabBar.interactionEnabled = self.captureController.tapToFocusEnabled && self.captureController.tapToExposureEnabled;
        }
    });
}

- (void)captureController:(CaptureController *)controller SavePhoto:(NSData *)data ToLibraryWithResult:(AssetSavedResult)result Error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (result == AssetSavedResultUnAuthorized) {
            UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Save Error"
                                                                                     message:@"please go to settings > videoCapture > Photos to allow we access to photo library to save your content"
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"ok"
                                                                style:UIAlertActionStyleDefault
                                                              handler:nil]];
            [self presentViewController:alertController animated:TRUE completion:nil];
        }
    });
}

- (void)captureController:(CaptureController *)controller DidStartRecordingToFileURL:(NSURL *)url {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.scrollableTabBar.interactionEnabled = FALSE;
        self.cameraSwitchButton.enabled = FALSE;
        [self.captureButton setSelected:TRUE];
    });
}

- (void)captureController:(CaptureController *)controller DidFinishRecordingToFileURL:(NSURL *)url Error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.scrollableTabBar.interactionEnabled = TRUE;
        self.cameraSwitchButton.enabled = TRUE;
        [self.captureButton setSelected:FALSE];
    });
}

- (void)captureController:(CaptureController *)controller DidCameraZoomToFactor:(CGFloat)factor {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"camera zoom factor: %f", factor);
        [self syncZoomSliderWithDeviceZoomLevel];
    });
}


@end
