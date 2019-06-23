//
//  VideoChapterItem.h
//  03_videoPlayer
//
//  Created by sy on 2019/6/22.
//  Copyright © 2019 sy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CMTime.h>
NS_ASSUME_NONNULL_BEGIN

@interface VideoChapterItem : NSObject

@property CMTime time;
@property (strong, nonatomic) NSString* title;

- (instancetype)initWithCMTime:(CMTime)time title:(NSString*)text;
@end

NS_ASSUME_NONNULL_END
