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



@interface VideoCell ()
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImage;
@property (weak, nonatomic) IBOutlet UILabel *titleLable;
@property (weak, nonatomic) IBOutlet UILabel *timeLable;


@property (strong, nonatomic) AVAsset* asset;
//@property (strong, nonatomic) AVAssetImageGenerator* imageGenerator;
@end




@implementation VideoCell

- (void)setUrl:(NSURL *)url {
    _url = url;
    NSLog(@"set url: %@", self.url);
    [self loadMediaData];
}

- (void)loadMediaData {
    self.asset = [AVAsset assetWithURL:self.url];
    NSArray* keys = @[COMMON_METADATA_KEY, METADATA_KEY, AVAILABLE_METADATA_FORMAT_KEY];
    [self.asset loadValuesAsynchronouslyForKeys:keys
                         completionHandler:^{
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [self updateView];
                             });
    
                         }];
}

- (void)updateView {
    NSLog(@"--- %@ ---", self.url.pathComponents.lastObject);
    if ([self.asset statusOfValueForKey:COMMON_METADATA_KEY error:nil] == AVKeyValueStatusLoaded) {
        NSLog(@"%@ load success.", COMMON_METADATA_KEY);
        for(AVMetadataItem* item in self.asset.commonMetadata) {
            NSLog(@"\t(keySpace:%@)key:%@, commonKey:%@, value:%@", item.keySpace, item.keyString, item.commonKey, item.value);
        }
        
        // generate video thumbnail image
        [self loadThumbnailImage];
        
        //setup title
        NSArray* titles = [AVMetadataItem metadataItemsFromArray:self.asset.commonMetadata
                                                         withKey:AVMetadataCommonKeyTitle
                                                        keySpace:AVMetadataKeySpaceCommon];
        if(titles.count > 0) {
            AVMetadataItem* item = (AVMetadataItem*)titles.firstObject;
            self.titleLable.text = item.stringValue;
        }else {
            self.titleLable.text = self.url.lastPathComponent;
        }
    }
    
    if ([self.asset statusOfValueForKey:METADATA_KEY error:nil] == AVKeyValueStatusLoaded) {
        NSLog(@"%@ load success.", METADATA_KEY);
        for(AVMetadataItem* item in self.asset.metadata) {
            NSLog(@"\t(keySpace: %@)key:%@, commonKey:%@, value:%@", item.keySpace, item.keyString, item.commonKey, item.value);
        }
    }
    
    if ([self.asset statusOfValueForKey:AVAILABLE_METADATA_FORMAT_KEY error:nil] == AVKeyValueStatusLoaded) {
        NSLog(@"%@ load success.", AVAILABLE_METADATA_FORMAT_KEY);
        NSMutableDictionary* metadatas_dic = [NSMutableDictionary dictionary];
        for(AVMetadataFormat fmt in self.asset.availableMetadataFormats) {
            NSArray* metadatas = [NSArray arrayWithArray:[self.asset metadataForFormat:fmt]];
            [metadatas_dic setValue:metadatas forKey:fmt];
        }
        NSLog(@"{");
        [metadatas_dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSLog(@"\t%@ : [", key);
            for (AVMetadataItem* item in (NSArray*)obj) {
                NSLog(@"\t\t%@ : %@ ,", item.keyString, item.value);
            }
            NSLog(@"\t]");
        }];
        NSLog(@"}");
    }
}

- (void)loadThumbnailImage {
    AVAssetImageGenerator* imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.asset];
    imageGenerator.maximumSize = CGSizeMake(self.thumbnailImage.frame.size.width, 0);
    CGImageRef thumbnailImage = [imageGenerator copyCGImageAtTime:CMTimeMakeWithSeconds(2, 1)
                                actualTime:NULL
                                     error:NULL];
    if (thumbnailImage) {
        self.thumbnailImage.image = [UIImage imageWithCGImage:thumbnailImage];
        self.thumbnailImage.layer.cornerRadius = 10;
        self.thumbnailImage.clipsToBounds = YES;
    }
}


@end
