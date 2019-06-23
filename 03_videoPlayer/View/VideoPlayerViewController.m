//
//  VideoPlayerViewController.m
//  03_videoPlayer
//
//  Created by sy on 2019/6/22.
//  Copyright © 2019 sy. All rights reserved.
//

#import "VideoPlayerViewController.h"
#import "Video/SYVideoPlayerController.h"



@interface VideoPlayerViewController ()

@property (weak, nonatomic) IBOutlet UIView *videoView;
@property (weak, nonatomic) IBOutlet UIView *extraView;

@end



@implementation VideoPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self.videoView.backgroundColor = [UIColor greenColor];
    self.videoController = [[SYVideoPlayerController alloc] initWithURL:self.url];
    if (self.videoController) {
        self.videoController.embedViewController = self;
        self.videoController.view.frame = CGRectMake(0, 0, self.videoView.frame.size.width, self.videoView.frame.size.height);
        [self.videoView addSubview:self.videoController.view];
     
//        NSLayoutConstraint* top = [NSLayoutConstraint constraintWithItem:self.videoController.view
//                                                                attribute:NSLayoutAttributeTop
//                                                                relatedBy:NSLayoutRelationEqual
//                                                                   toItem:self.videoView
//                                                                attribute:NSLayoutAttributeTop
//                                                               multiplier:1
//                                                                 constant:0];
//        NSLayoutConstraint* left = [NSLayoutConstraint constraintWithItem:self.videoController.view
//                                                                attribute:NSLayoutAttributeLeft
//                                                                relatedBy:NSLayoutRelationEqual
//                                                                   toItem:self.videoView
//                                                                attribute:NSLayoutAttributeLeft
//                                                               multiplier:1
//                                                                 constant:0];
//        NSLayoutConstraint* bottom = [NSLayoutConstraint constraintWithItem:self.videoController.view
//                                                                attribute:NSLayoutAttributeBottom
//                                                                relatedBy:NSLayoutRelationEqual
//                                                                   toItem:self.videoView
//                                                                attribute:NSLayoutAttributeBottom
//                                                               multiplier:1
//                                                                 constant:0];
//        NSLayoutConstraint* right = [NSLayoutConstraint constraintWithItem:self.videoController.view
//                                                                attribute:NSLayoutAttributeRight
//                                                                relatedBy:NSLayoutRelationEqual
//                                                                   toItem:self.videoView
//                                                                attribute:NSLayoutAttributeRight
//                                                               multiplier:1
//
//                                                                  constant:0];
//        self.videoController.view.translatesAutoresizingMaskIntoConstraints = FALSE;
//        [self.videoView addConstraints:@[top, left, bottom, right]];
    }
}


- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.videoController.view.frame = CGRectMake(0, 0, self.videoView.frame.size.width, self.videoView.frame.size.height);
    NSLog(@"video container frame: [x:%f, y:%f, width:%f, height:%f]", self.videoView.frame.origin.x,
          self.videoView.frame.origin.y, self.videoView.frame.size.width, self.videoView.frame.size.height);
    NSLog(@"video view frame: [x:%f, y:%f, width:%f, height:%f]", self.videoController.view.frame.origin.x,
          self.videoController.view.frame.origin.y, self.videoController.view.frame.size.width, self.videoController.view.frame.size.height);
}


- (void)viewWillDisappear:(BOOL)animated {
    [self.videoController clenup];
}

@end
