//
//  AVMetadataItem+SYAdditions.h
//  03_videoPlayer
//
//  Created by sy on 2019/6/21.
//  Copyright © 2019 sy. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVMetadataItem (SYAdditions)

@property (readonly) NSString* keyString;

@end

NS_ASSUME_NONNULL_END
