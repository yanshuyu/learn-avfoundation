//
//  VideoPlayerController.m
//  03_videoPlayer
//
//  Created by sy on 2019/6/22.
//  Copyright © 2019 sy. All rights reserved.
//

#import "VideoPlayerController.h"
#import "../../Category/UIView+SYAdditions.h"


#define PLAYER_ITEM_STATUS_CONTEXT @"PlayerItemStatusContext"
#define ROOT_VIEW_FRAME_CHANGE_CONTEXT @"RootViewFrameChangeContext"
#define PLAYER_ITEM_LOAD_RANGE_STATUS_CONTEXT @"PlayerItemLoadRangestatusContext"


@interface VideoPlayerController ()

@property (strong, nonatomic) UIView* view;
@property (strong, nonatomic) VideoControlView* controlView;
@property (strong, nonatomic) VideoContentView* contentView;

@property (assign, nonatomic) BOOL prepared;
@property (strong, nonatomic) AVAsset* asset;
@property (strong, nonatomic) AVPlayerItem* playerItem;
@property (strong, nonatomic) AVPlayer* player;

@property (nonatomic) float progressTimeInterval;
@property (strong, nonatomic) id progressTimer;

@property (nonatomic) float beginPlayAtPercentWhenPrepared;

@end



@implementation VideoPlayerController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 640, 320)];
        self.progressTimeInterval = 0.5;
        self.beginPlayAtPercentWhenPrepared = 0;
    }
    return self;
}


- (instancetype)initWithURL:(NSURL *)url {
    self = [self init];
    if (self) {
        self.url = url;
    }
    
    return self;
}


- (Class)controlLayerClass {
    return [VideoControlView class];
}


- (Class)contentLayerClass {
    return [VideoContentView class];
}


- (void)setFrame:(CGRect)frame {
    self.view.frame = frame;
    [self layoutSubViews];
}


- (void)layoutSubViews {
    self.contentView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.controlView.frame = self.contentView.frame;
}



- (void)setUrl:(NSURL *)url {
    if (_url == url){
        return;
    }
    self.prepared = FALSE;
    _url = url;
    [self prepareToPlay];

}


- (void)setPrepared:(BOOL)prepared {
    _prepared = prepared;
    if (prepared) {
        [self setupControlView];
    } else {
        [self resetControlView];
    }
}


- (void)prepareToPlay {
    if (self.prepared) {
        return;
    }
    
    NSArray* keys = @[@"duration", @"commonMetadata", @"tracks"];
    self.asset = [AVAsset assetWithURL:self.url];
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.asset automaticallyLoadedAssetKeys:keys];
    [self addVideoRequestTimer];
    
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.controlView = [[[self controlLayerClass] alloc] init];
    self.contentView = [[[self contentLayerClass] alloc] initWithPlayer:self.player];
    if (self.controlView && self.contentView) {
        self.controlView.delegate = self;
        [self.view removeAllSubViews];
        [self.view addSubview:self.contentView];
        [self.view addSubview:self.controlView];
        [self.controlView startLoadingActivity];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    //
    // request asset
    //
    if (context == PLAYER_ITEM_STATUS_CONTEXT) {
        if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) { // asset's required properties loaded success.
            NSLog(@"asset:%@ load success, prepare to play.", self.asset);
            [self removeVideoRequestTimer];
            self.prepared = YES;
        } else {
            NSLog(@"load asset:%@ failed, retry later again!", self.asset);
            UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Loading error"
                                                                                     message:@"Try again later"
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleDestructive
                                                             handler:^(UIAlertAction * _Nonnull action) {
                                                                 [alertController dismissViewControllerAnimated:true
                                                                                                     completion:nil];
                                                             }];
            [alertController addAction:okAction];
            [self.embedViewController presentViewController:alertController
                                                   animated:TRUE
                                                 completion:nil];
        }
    }
    
    //
    // updat cache loading
    //
    else if (context == PLAYER_ITEM_LOAD_RANGE_STATUS_CONTEXT) {
        NSLog(@"Cache info: [");
        for (NSValue* v in self.playerItem.loadedTimeRanges) {
            CMTimeRange cacheRange = [v CMTimeRangeValue];
            int64_t cacheStart = CMTimeGetSeconds(cacheRange.start);
            int64_t cacheLength = CMTimeGetSeconds(cacheRange.duration);
            NSLog(@"\t(%llds - %llds)", cacheStart, cacheLength);
        }
        NSLog(@"]");
        
        CMTimeRange cacheRange = [self.playerItem.loadedTimeRanges.firstObject CMTimeRangeValue];
        int64_t cacheStart = CMTimeGetSeconds(cacheRange.start);
        int64_t cacheLength= CMTimeGetSeconds(cacheRange.duration);
        int64_t totalLength = CMTimeGetSeconds(self.playerItem.duration);
        float percent =  (Float64) (cacheStart + cacheLength) / totalLength;
        [self.controlView setCacheLoadingProgress:percent];
    }
}


- (void)setupControlView {
    // hide loasding indicator
    [self.controlView stopLoadingActivity];
    
    //set title
    NSArray<AVMetadataItem*>* metadatas = [AVMetadataItem metadataItemsFromArray:self.asset.commonMetadata
                                                        withKey:AVMetadataCommonKeyTitle
                                                       keySpace:AVMetadataKeySpaceCommon];
    NSString* title = [self.url lastPathComponent];
    if (metadatas.count > 0) {
        title = metadatas.firstObject.stringValue;
    }
    [self.controlView setTitle:title];
    
    //playback status timer
    [self addProgressTimer];
    
    //cache loading timer
    [self addCacheLoadingTimer];
    
    [self.controlView beginAutoPlay];
    if (self.beginPlayAtPercentWhenPrepared != 0) {
        [self doScrubbingToPercent:self.beginPlayAtPercentWhenPrepared];
        self.beginPlayAtPercentWhenPrepared = 0;
    }
}


- (void)resetControlView {
    [self.controlView pause];
    [self.controlView startLoadingActivity];
    [self.controlView setCurrentTime:kCMTimeZero remainTime:kCMTimeZero];
    [self removeVideoRequestTimer];
    [self removeProgressTimer];
    [self removeCacheLoadingTimer];
}


//
// MARK: - playback status timer
//
- (void)addVideoRequestTimer {
    [self.playerItem addObserver:self
                      forKeyPath:@"status"
                         options:NSKeyValueObservingOptionNew
                         context:PLAYER_ITEM_STATUS_CONTEXT];
}

- (void)removeVideoRequestTimer {
    @try {
        [self.playerItem removeObserver:self
                             forKeyPath:@"status"
                                context:PLAYER_ITEM_STATUS_CONTEXT];
    } @catch (NSException *exception) {
        //do nothing
    }
}

- (void)addProgressTimer {
    if (!self.progressTimer) {
        CMTime interval = CMTimeMakeWithSeconds(self.progressTimeInterval, NSEC_PER_SEC);
        __weak VideoPlayerController* weakSelf = self;
        self.progressTimer = [self.player addPeriodicTimeObserverForInterval:interval
                                                                       queue:dispatch_get_main_queue()
                                                                  usingBlock:^(CMTime time) {
                                                                      CMTime remainTime = CMTimeSubtract(weakSelf.playerItem.duration, time);
                                                                      [weakSelf.controlView setCurrentTime:time remainTime:remainTime];
                                                                  }];
    }
}

- (void)removeProgressTimer {
    if (self.progressTimer) {
        [self.player removeTimeObserver:self.progressTimer];
        self.progressTimer = nil;
    }
}


- (void)addCacheLoadingTimer {
    [self.playerItem addObserver:self
                      forKeyPath:@"loadedTimeRanges"
                         options:NSKeyValueObservingOptionNew
                         context:PLAYER_ITEM_LOAD_RANGE_STATUS_CONTEXT];
}


- (void)removeCacheLoadingTimer {
    @try {
        [self.playerItem removeObserver:self
                             forKeyPath:@"loadedTimeRanges"
                                context:PLAYER_ITEM_LOAD_RANGE_STATUS_CONTEXT];
    } @catch (NSException *exception) {
        //do nothing
    }
}


- (void)doChangeVideoGravity:(AVLayerVideoGravity)gravity {
    
}

- (void)doChangeVideoSpeed:(float)speed {
    
}

- (void)doChangeVideoVolum:(float)volum {
    
}

- (void)doClose {
    [self resetControlView];
    if (self.embedViewController) {
        [self.embedViewController dismissViewControllerAnimated:TRUE completion:nil];
    }
}

- (void)doPause {
    [self.player pause];
}

- (void)doPlay {
    [self.player play];
}

- (void)doBeginScrub:(float)percent {
    [self removeProgressTimer];
    if (self.prepared) {
        [self.controlView pause];
        [self.controlView startLoadingActivity];
    }
}

- (void)doScrubbingToPercent:(float)percent {
    if (self.prepared) {
        float duration = CMTimeGetSeconds(self.playerItem.duration);
        float length = duration * percent;
        CMTime t = CMTimeMakeWithSeconds(length, NSEC_PER_SEC);
        [self.player cancelPendingPrerolls];
        [self.player seekToTime:t];
    }
}

- (void)doEndedScrub:(float)percent {
    if (!self.prepared) {
        self.beginPlayAtPercentWhenPrepared = percent;
    }else {
        [self.controlView play];
        [self.controlView stopLoadingActivity];
    }
    [self addProgressTimer];
}

- (void)doToggleFullScreen {
    
}

- (void)doToggleSubtitle {
    
}
    

@end
