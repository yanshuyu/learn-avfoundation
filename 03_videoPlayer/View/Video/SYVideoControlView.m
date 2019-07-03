//
//  SYVideoControlView.m
//  03_videoPlayer
//
//  Created by sy on 2019/6/22.
//  Copyright © 2019 sy. All rights reserved.
//

#import "SYVideoControlView.h"
#import "../../Supported/VideoPrograssBar.h"

@interface SYVideoControlView () <VideoPrograssBarDelegate>
@property (weak, nonatomic) IBOutlet UILabel *titleLable;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLable;
@property (weak, nonatomic) IBOutlet UILabel *remainTimeLable;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet VideoPrograssBar *progressBar;

@end

@implementation SYVideoControlView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self loadNib:@"VideoControlOverlay" Options:nil];
        UIImage* playImage = [UIImage imageNamed:@"icons8-circled-play-51"];
        UIImage* pauseImage = [UIImage imageNamed:@"icons8-pause-button-51"];
        [self.playButton setImage:playImage forState:UIControlStateNormal];
        [self.playButton setImage:pauseImage forState:UIControlStateSelected];
        [self.playButton setSelected:FALSE];
        [self.playButton setHighlighted:FALSE];
        self.progressBar.delegate = self;
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


- (IBAction)onPlayButtonClick:(UIButton *)sender {
    if (!sender.isSelected) {
        [self play];
    } else {
        [self pause];
    }
}

- (void)play {
    [super play];
    [self.playButton setSelected:TRUE];
}

- (void)pause {
    [super pause];
    [self.playButton setSelected:FALSE];
}

- (void)beginAutoPlay {
    [self onPlayButtonClick:self.playButton];
}

- (void)videoPrograssBar:(VideoPrograssBar *)videoPrograssBar didBeginScrub:(float)percent {
    [self beginScrub:percent];
}

- (void)videoPrograssBar:(VideoPrograssBar *)videoPrograssBar didScrubToPercent:(float)percent {
    [self scrubbingToPercent:percent];
}

- (void)videoPrograssBar:(VideoPrograssBar *)videoPrograssBar didEndedScrub:(float)percent {
    [self endedScrub:percent];
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


- (void)setTitle:(NSString *)title {
    self.titleLable.text = title;
}

- (void)setCurrentTime:(CMTime)current remainTime:(CMTime)remain {
    int64_t totalCurTime = CMTimeGetSeconds(current);
    int64_t totalRemainTime = CMTimeGetSeconds(remain);
    int64_t curMin = totalCurTime / 60;
    int64_t curSec = totalCurTime % 60;
    int64_t remMin = totalRemainTime / 60;
    int64_t remSec = totalRemainTime % 60;
    
    NSString* currentTimeStr = [NSString stringWithFormat:@"%02lld:%02lld", curMin, curSec];
    NSString* remainTimeStr = [NSString stringWithFormat:@"%02lld:%02lld", remMin, remSec];
    self.currentTimeLable.text = currentTimeStr;
    self.remainTimeLable.text = remainTimeStr;
    float progress = (Float64)totalCurTime / (totalCurTime + totalRemainTime);
    
    [self.progressBar setPlayBackProgress: progress];
}

- (void)setCacheLoadingProgress:(float)percent {
    [self.progressBar setLoadCacheProgress:percent];
}

@end
