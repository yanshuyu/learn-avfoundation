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


- (void)layoutSubviews {
    [super layoutSubviews];
    self.rootChild.frame = self.frame;
}

- (void)play {
    [self.delegate doPlay];
}

- (void)pause {
    [self.delegate doPause];
}

- (void)scrubbingToTime:(CMTime)t {
    [self.delegate doScrubbingToTime:t];
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

- (void)toggleChapter {
    
}

- (void)startLoadingActivity {
    
}

- (void)stopLoadingActivity {
    
}

@end
