//
//  SYCaptureViewController.m
//  04_videoCapture
//
//  Created by sy on 2019/7/9.
//  Copyright © 2019 sy. All rights reserved.
//

#import "SYCaptureViewController.h"
#import "../View/VideoPreviewView.h"
#import "../Controller/CaptureController.h"
#import "../Supported/ScrollableTabBar.h"

@interface SYCaptureViewController () <CaptureControllerDelegate, ScrollableTabBarDelegate>

@property (weak, nonatomic) IBOutlet VideoPreviewView *videoPreviewView;
@property (weak, nonatomic) IBOutlet UIView *scrollableTabBarContainer;


@property (strong, nonatomic) CaptureController* captureController;
@property (strong, nonatomic) ScrollableTabBar* scrollableTabBar;
@end

@implementation SYCaptureViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    //setup scrollable tab bar
    UIImageView* barItemSelectedIndicator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"select_indicator"]];
    barItemSelectedIndicator.frame = CGRectMake(0, 0, 12, 12);
    ScrollableTabBarItem* item1 = [[ScrollableTabBarItem alloc] initWithTitleString:@"Video"];
    ScrollableTabBarItem* item2 = [[ScrollableTabBarItem alloc] initWithTitleString:@"Photo"];
    ScrollableTabBarItem* item3 = [[ScrollableTabBarItem alloc] initWithTitleString:@"sgg"];
    ScrollableTabBarItem* item4 = [[ScrollableTabBarItem alloc] initWithTitleString:@"gdv"];
    ScrollableTabBarItem* item5 = [[ScrollableTabBarItem alloc] initWithTitleString:@"whisss"];
    ScrollableTabBarItem* item6 = [[ScrollableTabBarItem alloc] initWithTitleString:@"sfsfggs"];
    NSArray* barItems = [NSArray arrayWithObjects:item1, item2,item3, item4, item5, nil];
    self.scrollableTabBar = [[ScrollableTabBar alloc] initWithFrame:self.scrollableTabBarContainer.bounds
                                                              Items:barItems
                                                          ItemSpace:5
                                              SelectedItemIndicator:barItemSelectedIndicator
                                                           Delegate:self];
    [self.scrollableTabBarContainer addSubview:self.scrollableTabBar];
    //[self.view addSubview:self.scrollableTabBar];
    
    
    //setup capture session
    self.captureController = [CaptureController new];
    self.captureController.delegate = self;
    NSError* e;
    if ([self.captureController setupCaptureSessionWithPreset:AVCaptureSessionPresetMedium
                                                        Error:&e]) {
        [self.captureController setPreviewLayer:self.videoPreviewView];
        [self.captureController startSession];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.captureController cleanUpSession];
}


//
// MARK: - capture controller delegate
//
- (void)captureController:(CaptureController*)controller ConfigureSessionFailedWithError:(NSError*)error {
    NSLog(@"session configruation error: %@", error.localizedDescription);
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

- (BOOL)prefersStatusBarHidden {
    return TRUE;
}

- (IBAction)onPrevButtonTap:(UIButton *)sender {
    [self.scrollableTabBar jumpToItemAtIndex:self.scrollableTabBar.selectedIndex - 1 Animated:FALSE];
}

- (IBAction)onNextButtonTap:(UIButton *)sender {
    [self.scrollableTabBar jumpToItemAtIndex:self.scrollableTabBar.selectedIndex + 1 Animated:FALSE];
}


//
// MARK: - scrollable tab bar delegate
//
- (void)scrollableTabBar:(ScrollableTabBar *)bar SelectItem:(ScrollableTabBarItem *)item AtIndex:(int)index {
    NSLog(@"select at index: %d", index);
}

- (void)scrollableTabBar:(ScrollableTabBar *)bar DeselectItem:(ScrollableTabBarItem *)item AtIndex:(int)index {
    NSLog(@"deSelect at index: %d", index);
}


@end
