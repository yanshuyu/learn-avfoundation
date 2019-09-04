//
//  CameraRollManager.m
//  04_videoCapture
//
//  Created by sy on 2019/8/12.
//  Copyright © 2019 sy. All rights reserved.
//

#import "CameraRollManager.h"

//
// camera roll item
//
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





//
// camera roll manager
//
@interface CameraRollManager ()

@property (nonatomic) BOOL initailized;
@property (strong, nonatomic) PHFetchResult* fetchResults;
@property (strong, nonatomic) NSMutableArray* cameraRollItems;

@end


@implementation CameraRollManager

+ (instancetype)shareInstance {
    static CameraRollManager* instance = nil;
    static dispatch_once_t once_flag;
    dispatch_once(&once_flag, ^{
        instance = [CameraRollManager new];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.initailized = FALSE;
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    return self;
}

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}


- (NSArray<CameraRollItem*>*)fetchCameraRollItems {
    if (self.initailized) {
        return self.cameraRollItems;
    }
    
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
    
    self.fetchResults = assets;
    self.cameraRollItems = result;
    self.initailized = TRUE;
    
    return result;
}

- (void)fetchLatestCameraRollItemWithCompeletionHandler:(void (^)(CameraRollItem * _Nonnull))compeletionHandler {
    PHFetchOptions* option = [PHFetchOptions new];
    option.includeAssetSourceTypes = PHAssetSourceTypeUserLibrary | PHAssetSourceTypeCloudShared;
    option.sortDescriptors =  @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:FALSE]];
    option.fetchLimit = 1;
    PHFetchResult<PHAsset*>* reslut = [PHAsset fetchAssetsWithOptions:option];
    if (reslut.count > 0 && compeletionHandler) {
        compeletionHandler([CameraRollItem cameraRollItemWithAsset:[reslut objectAtIndex:reslut.count-1]]);
    }
}


- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHFetchResultChangeDetails* changeDetails = [changeInstance changeDetailsForFetchResult:self.fetchResults];
    if (changeDetails.hasIncrementalChanges) {
        if (changeDetails.removedIndexes.count > 0) {
            self.fetchResults = changeDetails.fetchResultAfterChanges;
            [self.cameraRollItems removeObjectsAtIndexes:changeDetails.removedIndexes];
            [[NSNotificationCenter defaultCenter] postNotificationName:CameraRollManagerChangeNoticification
                                                                object:self
                                                              userInfo:@{
                                                                         @"changeType" : @(CameraRollChangeTypeRemove),
                                                                         @"removeIndexSet" : changeDetails.removedIndexes,
                                                                         }];
        }
        
        if (changeDetails.insertedIndexes.count > 0) {
            self.fetchResults = changeDetails.fetchResultAfterChanges;
             __block NSInteger objIndex = 0;
            NSMutableArray* insertedItems = [NSMutableArray array];
            [changeDetails.insertedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                CameraRollItem* newItem = [CameraRollItem cameraRollItemWithAsset:(PHAsset*)changeDetails.insertedObjects[objIndex]];
                [self.cameraRollItems addObject:newItem];
                objIndex += 1;
                [insertedItems addObject:newItem];
            }];

            [[NSNotificationCenter defaultCenter] postNotificationName:CameraRollManagerChangeNoticification
                                                                object:self
                                                              userInfo:@{
                                                                         @"changeType" : @(CameraRollChangeTypeInsert),
                                                                         @"insertRollItems" : insertedItems,
                                                                         }];
        }
    }
}


- (void)reset {
    self.fetchResults = nil;
    self.cameraRollItems = nil;
    self.initailized = FALSE;
}

@end
