//
//  AudioRecoderController.h
//  02_audioRecoder
//
//  Created by sy on 2019/5/23.
//  Copyright © 2019 sy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AudioRecoderControllerDelegate <NSObject>

@optional
- (void)audioRecorderControllerRecordBegin:(BOOL)success;
- (void)audioRecorderControllerRecordPause;
- (void)audioRecorderControllerRecordFinish:(BOOL)success WithResult:(NSURL*)result;

@end



@interface AudioRecoderController : NSObject

@property(nonatomic, strong) AVAudioRecorder* audioRecorder;
@property(nonatomic, weak) id<AudioRecoderControllerDelegate> delegate;

- (instancetype)initWithURL:(NSURL*)url Settings:(NSDictionary<NSString*, id>*)settings;
- (BOOL)record;
- (void)pause;
- (void)stop;
- (BOOL)clearup:(NSError* _Nullable *)e;

@end

NS_ASSUME_NONNULL_END
