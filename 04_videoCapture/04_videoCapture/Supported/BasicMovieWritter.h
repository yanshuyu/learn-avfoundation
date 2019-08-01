//
//  BasicMovieWritter.h
//  04_videoCapture
//
//  Created by sy on 2019/8/1.
//  Copyright © 2019 sy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    MovieWritterResultUnKowned,
    MovieWritterResultUnsupportedFileType,
    MovieWritterResultUnSupportedInput,
    MovieWritterResultSuccess,
    MovieWritterResultFailed,
} MovieWritterResult;

typedef void(^AssetWritterCompletionHandler)(MovieWritterResult result, NSURL* _Nullable outputURL, NSError* _Nullable error);

@interface BasicMovieWritter : NSObject

- (instancetype)initWithFileType:(AVFileType)outputFileType Error:(NSError* _Nullable*)error;
- (BOOL)addWritterInputForMediaType:(AVMediaType)mediaType Settings:(NSDictionary*)settings Context:(NSString*)context Error:(NSError* _Nullable*)error;
- (void)appendMediaSampleBuffer:(CMSampleBufferRef)sampleBuffer WithInputContext:(NSString*)context;
- (BOOL)startWritting;
- (void)stopWrittingWithCompletionHandler:(AssetWritterCompletionHandler)completionHander;

@end

NS_ASSUME_NONNULL_END
