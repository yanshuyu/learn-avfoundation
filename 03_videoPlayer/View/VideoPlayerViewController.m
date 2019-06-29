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
    self.videoView.backgroundColor = [UIColor blackColor];
    
    self.videoController = [[SYVideoPlayerController alloc] initWithURL:self.url];
    if (self.videoController) {
        self.videoController.embedViewController = self;
        self.videoController.frame = CGRectMake(0, 0, self.videoView.frame.size.width, self.videoView.frame.size.height);
        [self.videoView addSubview:self.videoController.view];
    }
}


- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.videoController.frame = CGRectMake(0, 0, self.videoView.frame.size.width, self.videoView.frame.size.height);
}



- (BOOL)prefersStatusBarHidden{
    return  TRUE;
}

@end
