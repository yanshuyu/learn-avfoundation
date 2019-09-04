//
//  CameraRollManager.h
//  04_videoCapture
//
//  Created by sy on 2019/8/12.
//  Copyright © 2019 sy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "CameraRollManagerNotification.h"

NS_ASSUME_NONNULL_BEGIN

//
// camera roll item
//

@interface CameraRollItem : NSObject

@property (strong, nonatomic, readonly) PHAsset* asset;
@property (nonatomic, readonly) PHAssetMediaType mediaType;
@property (strong, nonatomic, nullable, readonly) NSDate* creationDate;
@property (strong, nonatomic, nullable, readonly) NSDate* modificationDate;
@property (nonatomic, readonly) NSTimeInterval duration;
@property (strong, nonatomic, nullable) UIImage* thumbnailImage;
@property (nonatomic, readonly) BOOL icloludeAsset;

- (instancetype)initWithAsset:(PHAsset*)asset;
+ (instancetype)cameraRollItemWithAsset:(PHAsset*)asset;
- (void)generateThumbnailImageWithTargetSize:(CGSize)size
                                  contentMode:(PHImageContentMode)contentMode
                            completionHandler:(nullable void (^)(UIImage* _Nullable, NSError* _Nullable))completionHandler;
@end






//
// camera roll manager
//
typedef enum : NSUInteger {
    CameraRollChangeTypeInsert,
    CameraRollChangeTypeRemove,
    CameraRollChangeTypeUpdate,
} CameraRollChangeType;


@interface CameraRollManager : NSObject <PHPhotoLibraryChangeObserver>


+ (instancetype)shareInstance;
- (NSArray<CameraRollItem*>*)fetchCameraRollItems;
- (void)fetchLatestCameraRollItemWithCompeletionHandler:(nullable void (^)(CameraRollItem*))compeletionHandler;
- (void)reset;

@end

NS_ASSUME_NONNULL_END
