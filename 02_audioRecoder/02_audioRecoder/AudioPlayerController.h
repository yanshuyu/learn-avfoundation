//
//  AudioPlayerController.h
//  02_audioRecoder
//
//  Created by sy on 2019/5/23.
//  Copyright © 2019 sy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioPlayerController : NSObject

@property(readonly, getter=isPlaying) BOOL playing;

- (instancetype)initWithData:(NSData *)data error:(NSError * _Nullable *)outError;
- (instancetype)initWithContentsOfURL:(NSURL *)url error:(NSError * _Nullable *)outError;
- (BOOL)isPlaying;
- (BOOL)play;
- (void)pause;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
