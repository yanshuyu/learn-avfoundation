//
//  VideoCell.m
//  03_videoPlayer
//
//  Created by sy on 2019/6/20.
//  Copyright © 2019 sy. All rights reserved.
//

#import "VideoCell.h"
#import "../../Category/AVMetadataItem+SYAdditions.h"

#define CREATED_DAY_KEY @"creationDate"
#define COMMON_METADATA_KEY @"commonMetadata"
#define METADATA_KEY @"metadata"
#define AVAILABLE_METADATA_FORMAT_KEY @"availableMetadataFormats"
#define DURATION_KEY @"duration"
#define TRACKS_KEY @"tracks"

#define PLAYER_ITEM_STATUS_CONTEXT @"player_item_status_context"

#define THUMBNAIL_IMAGE_BEGIN_TIME 3



@interface VideoCell ()
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImage;
@property (weak, nonatomic) IBOutlet UILabel *titleLable;
@property (weak, nonatomic) IBOutlet UILabel *timeLable;

@property (strong, nonatomic) AVAsset* asset;
@property (strong, atomic) AVAssetImageGenerator* imageGenerator;

@end


@implementation VideoCell



- (void)setUrl:(NSURL *)url {
    _url = url;
    [self loadMediaData];
}


- (void)loadMediaData {
    self.asset = [AVAsset assetWithURL:self.url];
    NSArray* keys = @[DURATION_KEY,COMMON_METADATA_KEY];
    [self.asset loadValuesAsynchronouslyForKeys:keys
                         completionHandler:^{
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [self updateView];
                             });
                         }];

}


- (void)updateView {
    NSLog(@"--- %@ ---", self.url.pathComponents.lastObject);
    [self loadThumbnailImage];
    
    //setup title
    if ([self.asset statusOfValueForKey:COMMON_METADATA_KEY error:nil] == AVKeyValueStatusLoaded) {
        NSLog(@"%@ load success.", COMMON_METADATA_KEY);
        for(AVMetadataItem* item in self.asset.commonMetadata) {
            NSLog(@"\t(keySpace:%@)key:%@, commonKey:%@, value:%@", item.keySpace, item.keyString, item.commonKey, item.value);
        }

        NSArray* titles = [AVMetadataItem metadataItemsFromArray:self.asset.commonMetadata
                                                         withKey:AVMetadataCommonKeyTitle
                                                        keySpace:AVMetadataKeySpaceCommon];
        if(titles.count > 0) {
            AVMetadataItem* item = (AVMetadataItem*)titles.firstObject;
            self.titleLable.text = item.stringValue;
        }else {
            self.titleLable.text = [self.url.lastPathComponent stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@", self.url.pathExtension]
                                                                                         withString:@"" ];
        }
        
    }
    
    if ([self.asset statusOfValueForKey:DURATION_KEY error:nil] == AVKeyValueStatusLoaded) {
        uint durationInSec = CMTimeGetSeconds(self.asset.duration);
        uint hour = durationInSec / 60;
        uint sec = durationInSec % 60;
        self.timeLable.text = [NSString stringWithFormat:@"%02d:%02d", hour, sec];
    }
    
//
//    if ([self.asset statusOfValueForKey:METADATA_KEY error:nil] == AVKeyValueStatusLoaded) {
//        NSLog(@"%@ load success.", METADATA_KEY);
//        for(AVMetadataItem* item in self.asset.metadata) {
//            NSLog(@"\t(keySpace: %@)key:%@, commonKey:%@, value:%@", item.keySpace, item.keyString, item.commonKey, item.value);
//        }
//    }
//
//    if ([self.asset statusOfValueForKey:AVAILABLE_METADATA_FORMAT_KEY error:nil] == AVKeyValueStatusLoaded) {
//        NSLog(@"%@ load success.", AVAILABLE_METADATA_FORMAT_KEY);
//        NSMutableDictionary* metadatas_dic = [NSMutableDictionary dictionary];
//        for(AVMetadataFormat fmt in self.asset.availableMetadataFormats) {
//            NSArray* metadatas = [NSArray arrayWithArray:[self.asset metadataForFormat:fmt]];
//            [metadatas_dic setValue:metadatas forKey:fmt];
//        }
//        NSLog(@"{");
//        [metadatas_dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
//            NSLog(@"\t%@ : [", key);
//            for (AVMetadataItem* item in (NSArray*)obj) {
//                NSLog(@"\t\t%@ : %@ ,", item.keyString, item.value);
//            }
//            NSLog(@"\t]");
//        }];
//        NSLog(@"}");
//    }
}

- (void)loadThumbnailImage {
    self.imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.asset];
    self.imageGenerator.appliesPreferredTrackTransform = TRUE;
    self.imageGenerator.maximumSize = CGSizeMake(self.thumbnailImage.frame.size.width, 0);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CMTime t = CMTimeMake(THUMBNAIL_IMAGE_BEGIN_TIME, 1);
        NSError* e;
        CGImageRef thumbnail = [self.imageGenerator copyCGImageAtTime:t actualTime:nil error:&e];
        if (thumbnail) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.thumbnailImage.image = [UIImage imageWithCGImage:thumbnail];
            });
        } else {
            NSLog(@"Generate thumbnail for %@, error: %@", self.url.path, e.localizedDescription);
        }
    });
}


- (void)setThumbnailImage:(UIImageView *)thumbnailImage {
    _thumbnailImage = thumbnailImage;
    self.thumbnailImage.layer.cornerRadius = 10;
    self.thumbnailImage.layer.masksToBounds = TRUE;
}


- (void)prepareForReuse {
    [super prepareForReuse];
    _thumbnailImage.image = nil;
    _titleLable.text = @"";
    _timeLable.text = @"";
    _asset = nil;
    _imageGenerator = nil;
}


@end
