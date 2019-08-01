//
//  BasicMovieWritter.m
//  04_videoCapture
//
//  Created by sy on 2019/8/1.
//  Copyright © 2019 sy. All rights reserved.
//

#import "BasicMovieWritter.h"
#import <AVFoundation/AVFoundation.h>
#import "../Caeogory/NSURL+SYAddition.h"

#define BASIC_MOVIE_WRITTER_DOMAIN @"com.sy.videoCapture.basicMovieWritter"

@interface BasicMovieWritter ()

@property (strong, nonatomic) AVAssetWriter* assetWriter;
@property (strong, nonatomic) NSMutableDictionary* assetWritterInputs;
@property (nonatomic) BOOL isWritting;
@property (nonatomic) BOOL isFirstSample;

@end

@implementation BasicMovieWritter

- (instancetype)initWithFileType:(AVFileType)outputFileType Error:(NSError *__autoreleasing  _Nullable * _Nullable)error{
    self = [super init];
    if (self) {
        if (![[BasicMovieWritter supportedFileTypes] objectForKey:outputFileType]) {
            if (error) {
                __autoreleasing NSError* e = [NSError errorWithDomain:BASIC_MOVIE_WRITTER_DOMAIN
                                                 code:MovieWritterResultUnsupportedFileType
                                             userInfo:@{
                                                        (id)kCFErrorLocalizedDescriptionKey:@"unsuportted output file type"
                                                        }];
                error = &e;
            }
            return Nil;
        }
        
        NSString* extendsion = [BasicMovieWritter supportedFileTypes][outputFileType];
        self.assetWriter = [AVAssetWriter assetWriterWithURL:[NSURL uniqueFileURLAtDirectory:NSTemporaryDirectory() FileExtension:extendsion]
                                                    fileType:outputFileType
                                                       error: error];
        if (!self.assetWriter) {
            return Nil;
        }
        
        self.assetWritterInputs = [NSMutableDictionary dictionary];
        self.isWritting = FALSE;
        self.isFirstSample = TRUE;
    }
    
    
    return self;
}

+ (NSDictionary*)supportedFileTypes {
    return @{
             AVFileTypeMPEG4:@"mp4",
             AVFileTypeAppleM4V:@"m4v",
             AVFileTypeQuickTimeMovie:@"mov",
             };
}

- (BOOL)addWritterInputForMediaType:(AVMediaType)mediaType Settings:(NSDictionary *)settings Context:(nonnull NSString *)context Error:(NSError *__autoreleasing  _Nullable * _Nullable)error{
    AVAssetWriterInput* assetWritterInput = [AVAssetWriterInput assetWriterInputWithMediaType:mediaType outputSettings:settings];
    if (assetWritterInput) {
        if ([self.assetWriter canAddInput:assetWritterInput]) {
            assetWritterInput.expectsMediaDataInRealTime = TRUE;
            [self.assetWriter addInput:assetWritterInput];
            [self.assetWritterInputs setValue:assetWritterInput forKey:context];
            return TRUE;
        } else {
            if (error) {
                __autoreleasing NSError* e = [NSError errorWithDomain:BASIC_MOVIE_WRITTER_DOMAIN
                                                                 code:MovieWritterResultUnSupportedInput
                                                             userInfo:@{
                                                                        (id)kCFErrorLocalizedDescriptionKey:@"unsuportted asset writter input"
                                                                        }];
                error = &e;
            }
        }
    }
    
    return FALSE;
}

- (void)appendMediaSampleBuffer:(CMSampleBufferRef)sampleBuffer WithInputContext:(NSString *)context {
    if (!self.isWritting) {
        return;
    }
    
    AVAssetWriterInput* writterInput = [self.assetWritterInputs objectForKey:context];
    if (writterInput) {
        CMFormatDescriptionRef ftmDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
        CMMediaType sampleMediaType = CMFormatDescriptionGetMediaType(ftmDesc);
        if (sampleMediaType == kCMMediaType_Video) {
            if (self.isFirstSample) {
                CMTime t = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                [self.assetWriter startSessionAtSourceTime:t];
                self.isFirstSample = FALSE;
            }
           
            if (writterInput.readyForMoreMediaData) {
                [writterInput appendSampleBuffer:sampleBuffer];
            }
            
        } else if (sampleMediaType == kCMMediaType_Audio) {
            if (!self.isFirstSample && writterInput.readyForMoreMediaData) {
                [writterInput appendSampleBuffer:sampleBuffer];
            }
        }
        
    }
}

- (BOOL)startWritting {
    self.isWritting = [self.assetWriter startWriting];
    return  self.isWritting;
}

-(void)stopWrittingWithCompletionHandler:(AssetWritterCompletionHandler)completionHander {
    self.isFirstSample = TRUE;
    self.isWritting = FALSE;
    [self.assetWriter finishWritingWithCompletionHandler:^{
        AVAssetWriterStatus status = self.assetWriter.status;
        if (status == AVAssetWriterStatusCompleted) {
            completionHander(MovieWritterResultSuccess, self.assetWriter.outputURL, Nil);
        } else if (status == AVAssetWriterStatusFailed) {
            completionHander(MovieWritterResultFailed, Nil, self.assetWriter.error);
        }
    }];
}

@end
