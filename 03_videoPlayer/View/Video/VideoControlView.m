//
//  VideoControlView.m
//  03_videoPlayer
//
//  Created by sy on 2019/6/22.
//  Copyright © 2019 sy. All rights reserved.
//

#import "VideoControlView.h"
#import "../../Category/UIView+SYAdditions.h"


@interface VideoControlView ()

@property (strong, nonatomic) UIView* rootChild;

@end




@implementation VideoControlView

- (instancetype)initWithNib:(NSString *)name Delegate:(id<VideoControlDelegate>)delegate {
    self = [super init];
    if (self) {
        [self loadNib:name Options:nil];
        self.delegate = delegate;
    }
    
    return self;
}

- (BOOL)loadNib:(NSString *)name Options:(NSDictionary<UINibOptionsKey,id> *)options {
    BOOL success = NO;
    NSArray* topLevelViews = [[NSBundle mainBundle] loadNibNamed:name
                                                           owner:self
                                                         options:options];
    if (topLevelViews.count > 0){
        //remove all subView
        [self removeAllSubViews];
        
        self.rootChild = (UIView*)topLevelViews.firstObject;
        [self addSubview:self.rootChild];
        self.rootChild.frame = self.frame;
        success = YES;
    }
    
    NSLog(@"%s %d,  load nib file: %@,  success: %d", __FILE__, __LINE__, name, success);
    return success;
}

- (void)play {
    [self.delegate doPlay];
}

- (void)beginAutoPlay {
    
}

- (void)pause {
    [self.delegate doPause];
}

- (void)beginScrub:(float)percent {
    [self.delegate doBeginScrub:percent];
}

- (void)scrubbingToPercent:(float)percent {
    [self.delegate doScrubbingToPercent:percent];
}

- (void)endedScrub:(float)percent {
    [self.delegate doEndedScrub:percent];
}

- (void)changeVideoGravity:(AVLayerVideoGravity)gravity {
    [self.delegate doChangeVideoGravity:gravity];
}

- (void)changeSpeed:(float)speed {
    [self.delegate doChangeVideoSpeed:speed];
}

- (void)changeVolum:(float)volum {
    [self.delegate doChangeVideoVolum:volum];
}

- (void)toggleScreen {
    [self.delegate doToggleFullScreen];
}

- (void)toggleSubtitle {
    [self.delegate doToggleSubtitle];
}

- (void)close {
    [self.delegate doClose];
}


- (void)setTitle:(NSString *)title {
    
}

- (void)setCurrentTime:(CMTime)current remainTime:(CMTime)remain {
    
}

- (void)setCacheLoadingProgress:(float)percent {
    
}

- (void)toggleChapter {
    [self.delegate doToggleChapters];
}

- (void)startLoadingActivity {
    
}

- (void)stopLoadingActivity {
    
}

@end
