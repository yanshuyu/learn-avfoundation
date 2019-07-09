//
//  VideoPlayerViewController.h
//  03_videoPlayer
//
//  Created by sy on 2019/6/22.
//  Copyright © 2019 sy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Video/VideoPlayerController.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    TableViewModeNone,
    TableViewModeSubTitles,
    TableViewModeChapters,
} TableViewMode;

@interface VideoPlayerViewController : UIViewController <VideoPlayerControllerDelegate>

@property (weak, nonatomic) NSURL* url;
@property (strong, nonatomic) VideoPlayerController* videoController;

@end

NS_ASSUME_NONNULL_END
