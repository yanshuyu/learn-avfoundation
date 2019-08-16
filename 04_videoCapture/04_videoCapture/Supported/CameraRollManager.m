//
//  CameraRollManager.m
//  04_videoCapture
//
//  Created by sy on 2019/8/12.
//  Copyright © 2019 sy. All rights reserved.
//

#import "CameraRollManager.h"

@interface CameraRollItem ()
@property (strong, nonatomic) PHAsset* asset;
@property (nonatomic) BOOL thumbnailImageReady;
@property (nonatomic) CGSize lastGenerateThumbnailImageSize;
@property (nonatomic) PHImageContentMode lastGenerateThumbnailImageContentMode;
@property (nonatomic, readwrite) BOOL icloludeAsset;

@end



@implementation CameraRollItem

- (instancetype)initWithAsset:(PHAsset *)asset {
    self = [super init];
    if (!self) {
        return Nil;
    }
    self.asset = asset;
    self.thumbnailImage = nil;
    self.thumbnailImageReady = false;
    self.lastGenerateThumbnailImageSize = CGSizeZero;
    self.lastGenerateThumbnailImageContentMode = PHImageContentModeDefault;
    self.icloludeAsset = FALSE;
    
    return self;
}

+ (instancetype)cameraRollItemWithAsset:(PHAsset *)asset {
    return [[CameraRollItem alloc] initWithAsset:asset];
}

- (void)generateThumbnailImageWithTargetSize:(CGSize)size
                                 contentMode:(PHImageContentMode)contentMode
                           completionHandler:(void (^)(UIImage * _Nullable, NSError * _Nullable))completionHandler {
    if (CGSizeEqualToSize(size, self.lastGenerateThumbnailImageSize)
        && contentMode == self.lastGenerateThumbnailImageContentMode
        && self.thumbnailImageReady) {
        completionHandler(self.thumbnailImage, nil);
    }
    self.thumbnailImageReady = FALSE;
    self.lastGenerateThumbnailImageSize = size;
    self.lastGenerateThumbnailImageContentMode = contentMode;
    self.thumbnailImage = nil;
    
    [[PHImageManager defaultManager] requestImageForAsset:self.asset
                                               targetSize:size
                                              contentMode:contentMode
                                                  options:nil
                                            resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                if (!result && info) {
                                                    completionHandler(nil, (NSError*)[info objectForKey:PHImageErrorKey]);
                                                }
                                                self.thumbnailImage = result;
                                                self.icloludeAsset = [info objectForKey:PHImageResultIsInCloudKey];
                                                self.thumbnailImageReady = TRUE;
                                                completionHandler(result, nil);
                                            }];
}

- (PHAssetMediaType)mediaType {
    return self.asset.mediaType;
}

- (NSDate *)creationDate {
    return self.asset.creationDate;
}

- (NSDate *)modificationDate {
    return self.asset.modificationDate;
}

- (NSTimeInterval)duration {
    return self.asset.duration;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"[CameraRollItem: (mediaType:%ld), (creationDate:%@), (modificationDate:%@), (duration:%f)]", (long)self.mediaType, self.creationDate, self.modificationDate, self.duration];
}

@end



@implementation CameraRollManager

- (NSArray<CameraRollItem*>*)fetchCameraRollItems {
    NSMutableArray<CameraRollItem*>* result = [NSMutableArray array];
    PHFetchOptions* albumsFetchOption = [[PHFetchOptions alloc] init];
    albumsFetchOption.includeAssetSourceTypes = PHAssetSourceTypeUserLibrary | PHAssetSourceTypeCloudShared;
    albumsFetchOption.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:TRUE]];
//    PHFetchResult<PHAssetCollection*>* albums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
//                                                                                         subtype:PHAssetCollectionSubtypeAny
//                                                                                         options:albumsFetchOption];
//    [albums enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        PHFetchResult<PHAsset*>* assetInAlbum = [PHAsset fetchAssetsInAssetCollection:obj options:albumsFetchOption];
//        [assetInAlbum enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//            CameraRollItem* item = [CameraRollItem cameraRollItemWithAsset:obj];
//            [result addObject:item];
//        }];
//    }];
    PHFetchResult<PHAsset*>* assets  = [PHAsset fetchAssetsWithOptions:albumsFetchOption];
    [assets enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CameraRollItem* item = [CameraRollItem cameraRollItemWithAsset:obj];
        [result addObject:item];
    }];
    
    return result;
}

@end
