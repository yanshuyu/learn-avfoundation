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



@interface VideoPlayerController ()
@property (strong, nonatomic) UIView* rootView;

@property (strong, nonatomic) VideoControlView* controlView;
@property (strong, nonatomic) VideoContentView* contentView;

@property (assign, nonatomic) BOOL prepared;
@property (strong, nonatomic) AVAsset* asset;
@property (strong, nonatomic) AVPlayerItem* playerItem;
@property (strong, nonatomic) AVPlayer* player;

@end



@implementation VideoPlayerController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.rootView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 640, 320)];
        [self.rootView addObserver:self
                        forKeyPath:@"frame"
                        options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                        context:ROOT_VIEW_FRAME_CHANGE_CONTEXT];
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


- (void)setUrl:(NSURL *)url {
    self.prepared = FALSE;
    _url = url;
    [self prepareToPlay];
}


- (UIView *)view {
    return self.rootView;
}


- (void)setPrepared:(BOOL)prepared {
    _prepared = prepared;
    if (prepared) {
        [self.controlView stopLoadingActivity];
    } else {
        [self.controlView startLoadingActivity];
    }
}


- (void)layoutSubViews {
    self.contentView.frame = CGRectMake(0, 0, self.rootView.frame.size.width, self.rootView.frame.size.height);
    self.controlView.frame = self.contentView.frame;
}


- (void)prepareToPlay {
    if (self.prepared) {
        return;
    }
    
    
    NSArray* keys = @[@"duration", @"commonMetadata", @"tracks"];
    self.asset = [AVAsset assetWithURL:self.url];
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.asset
                           automaticallyLoadedAssetKeys:keys];
    [self.playerItem addObserver:self
                      forKeyPath:@"status"
                         options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                         context:PLAYER_ITEM_STATUS_CONTEXT];
    
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.controlView = [[[self controlLayerClass] alloc] init];
    self.contentView = [[[self contentLayerClass] alloc] initWithPlayer:self.player];
    if (self.controlView && self.contentView) {
        self.controlView.delegate = self;
        [self layoutSubViews];
        [self.rootView removeAllSubViews];
        [self.rootView addSubview:self.contentView];
        [self.rootView addSubview:self.controlView];
    }
    self.prepared = FALSE;
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (context == PLAYER_ITEM_STATUS_CONTEXT) {
        [self.playerItem removeObserver:self
                             forKeyPath:@"status"
                                context:PLAYER_ITEM_STATUS_CONTEXT];
        if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) { // asset's required properties loaded success.
            NSLog(@"asset:%@ load success, prepare to play.", self.asset);
            self.prepared = YES;
        } else {
            NSLog(@"load asset:%@ failed, unkonw error!", self.asset);
        }
    } else if (context == ROOT_VIEW_FRAME_CHANGE_CONTEXT) {
        NSLog(@"%@:  %@", ROOT_VIEW_FRAME_CHANGE_CONTEXT, change);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self layoutSubViews];
        });
    }
}


- (void)clenup {
    @try {
        [self.playerItem removeObserver:self
                             forKeyPath:@"status"
                                context:PLAYER_ITEM_STATUS_CONTEXT];
    } @catch (NSException *exception) {
        
    }
    
    @try {
        [self.rootView removeObserver:self
                           forKeyPath:@"frame"
                              context:ROOT_VIEW_FRAME_CHANGE_CONTEXT];
    } @catch (NSException *exception) {
        
    }
}


- (void)doChangeVideoGravity:(AVLayerVideoGravity)gravity {
    
}

- (void)doChangeVideoSpeed:(float)speed {
    
}

- (void)doChangeVideoVolum:(float)volum {
    
}

- (void)doClose {
    if (self.embedViewController) {
        [self.embedViewController dismissViewControllerAnimated:TRUE completion:nil];
    }
}

- (void)doPause {
    
}

- (void)doPlay {
    [self.player play];
}

- (void)doScrubbingToTime:(CMTime)t {
    
}

- (void)doToggleFullScreen {
    
}

- (void)doToggleSubtitle {
    
}

@end
