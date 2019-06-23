//
//  SYVideoControlView.m
//  03_videoPlayer
//
//  Created by sy on 2019/6/22.
//  Copyright © 2019 sy. All rights reserved.
//

#import "SYVideoControlView.h"

@interface SYVideoControlView ()
@property (weak, nonatomic) IBOutlet UILabel *titleLable;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLable;
@property (weak, nonatomic) IBOutlet UILabel *remainTimeLable;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@end

@implementation SYVideoControlView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self loadNib:@"VideoControlOverlay" Options:nil];
    }
    return self;
}

- (IBAction)onBackButtonClick:(UIButton *)sender {
    [self close];
}

- (IBAction)onChapterButtonClick:(UIButton *)sender {
    [self toggleChapter];
}

- (IBAction)onToggleScreenButtonClick:(UIButton *)sender {
    [self toggleScreen];
}

- (IBAction)onVolumButtonClick:(UIButton *)sender {
    // show volum ajustment view
}

- (IBAction)onTimeScrubbingSliding:(UISlider *)sender {
    
}

- (IBAction)onPlayButtonClick:(UIButton *)sender {
    [super play];
}

- (void)startLoadingActivity {
    self.loadingIndicator.hidden = FALSE;
    self.playButton.hidden = TRUE;
    [self.loadingIndicator startAnimating];
}

- (void)stopLoadingActivity {
    self.loadingIndicator.hidden = TRUE;
    self.playButton.hidden = FALSE;
    [self.loadingIndicator stopAnimating];
}

@end
