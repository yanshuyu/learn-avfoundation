//
//  CameraRollBrowserViewController.m
//  04_videoCapture
//
//  Created by sy on 2019/8/12.
//  Copyright © 2019 sy. All rights reserved.
//

#import "CameraRollBrowserViewController.h"
#import "../Supported/CameraRollManager.h"
#import "../View/CameraRollItemCell.h"
#import "../Supported/SYCollectionViewCoverFlowLayout.h"

#define CELL_SIZE CGSizeMake(122, 122)


typedef enum : NSUInteger {
    CameraRollSegmentAll,
    CameraRollSegmentPhoto,
    CameraRollSegmentVideo,
    CameraRollSegmentNone,
} CameraRollSegment;


@interface CameraRollBrowserViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *rollItemSegmentContrl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *layoutSegmentContrl;

@property (strong, nonatomic) NSMutableArray<CameraRollItem*>* allCameraRollItems;
@property (strong, nonatomic) NSArray<CameraRollItem*>* currentViewingCameraRollItems;
@property (strong, nonatomic) UIView* blurEffectView;

@property (strong, nonatomic) UICollectionViewFlowLayout* basicFlowLayout;
@property (strong, nonatomic) SYCollectionViewCoverFlowLayout* coverFlowLayout;

@end

@implementation CameraRollBrowserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
    
    CameraRollManager* cameraRollMgr = [CameraRollManager new];
    self.allCameraRollItems = [NSMutableArray arrayWithArray:[cameraRollMgr fetchCameraRollItems]];
    self.rollItemSegmentContrl.selectedSegmentIndex = 0;
    self.layoutSegmentContrl.selectedSegmentIndex = 0;
    [self handleRollItemSegmentControlValueChange:self.rollItemSegmentContrl];
    [self handleLayoutSegmentControlValueChange:self.layoutSegmentContrl];
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentViewingCameraRollItems.count-1 inSection:0]
                                atScrollPosition:UICollectionViewScrollPositionBottom
                                        animated:FALSE];
}

- (void)setupView {
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    UICollectionViewFlowLayout* flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.minimumLineSpacing = 4;
    flowLayout.minimumInteritemSpacing = 4;
    flowLayout.itemSize = CELL_SIZE;
    self.basicFlowLayout = flowLayout;
    self.collectionView.collectionViewLayout = flowLayout;
    self.collectionView.backgroundColor = [UIColor blackColor];
    self.collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    UIVisualEffectView* segmentBlurOverlayView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    segmentBlurOverlayView.frame = self.rollItemSegmentContrl.frame;
    [self.view insertSubview:segmentBlurOverlayView belowSubview:self.rollItemSegmentContrl];
    segmentBlurOverlayView.layer.cornerRadius = 4;
    segmentBlurOverlayView.layer.masksToBounds = TRUE;
    self.blurEffectView = segmentBlurOverlayView;
//    [self.rollItemSegmentContrl.leadingAnchor constraintEqualToAnchor:segmentBlurOverlayView.leadingAnchor constant:0].active = TRUE;
//    [self.rollItemSegmentContrl.trailingAnchor constraintEqualToAnchor:segmentBlurOverlayView.trailingAnchor constant:0].active = TRUE;
//    [self.rollItemSegmentContrl.topAnchor constraintEqualToAnchor:segmentBlurOverlayView.topAnchor constant:0].active = TRUE;
//    [self.rollItemSegmentContrl.bottomAnchor constraintEqualToAnchor:segmentBlurOverlayView.bottomAnchor constant:0].active = TRUE;

}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.blurEffectView.frame = self.rollItemSegmentContrl.frame;
}

- (void)configCameraRollCell:(CameraRollItemCell*)cell WithModel:(CameraRollItem*)item {
    if (item.mediaType == PHAssetMediaTypeImage) {
        
    } else if (item.mediaType == PHAssetMediaTypeVideo) {
        cell.durationLable.text = [NSString stringWithFormat:@"%02d:%02d", ((int)item.duration)/60,((int)item.duration)%60];
        cell.durationLable.hidden = FALSE;
    }
    
    [item generateThumbnailImageWithTargetSize:CELL_SIZE
                                   contentMode:PHImageContentModeAspectFit
                             completionHandler:^(UIImage * _Nullable image, NSError*  _Nullable error) {
                                 if (image) {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         cell.thumnailImageView.image = image;
                                         cell.cloudeImageView.hidden = !item.icloludeAsset;
                                     });
                                 } else if (error) {
                                     NSLog(@"%@ generate thumbnail image failed, error: %@", item, error);
                                 }
                             }];
}


- (void)filterCameraRollItemsBySegment:(CameraRollSegment)segment {
    NSMutableArray<CameraRollItem*>* result = [NSMutableArray array];
    if (segment == CameraRollSegmentAll) {
        result = self.allCameraRollItems;
    } else if (segment == CameraRollSegmentPhoto) {
        [self.allCameraRollItems enumerateObjectsUsingBlock:^(CameraRollItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.mediaType == PHAssetMediaTypeImage) {
                [result addObject:obj];
            }
        }];
    } else if (segment == CameraRollSegmentVideo) {
        [self.allCameraRollItems enumerateObjectsUsingBlock:^(CameraRollItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.mediaType == PHAssetMediaTypeVideo) {
                [result addObject:obj];
            }
        }];
    }
    
    self.currentViewingCameraRollItems = result;
}


- (IBAction)handleCloseButtonTap:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:TRUE completion:nil];
}


- (IBAction)handleLayoutSegmentControlValueChange:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        //[self.collectionView setCollectionViewLayout:self.basicFlowLayout animated:TRUE];
        self.collectionView.collectionViewLayout = self.basicFlowLayout;
        [self.collectionView.collectionViewLayout invalidateLayout];
    } else if (sender.selectedSegmentIndex == 1) {
        if (!self.coverFlowLayout) {
            self.coverFlowLayout = [[SYCollectionViewCoverFlowLayout alloc] initWithCollectionViewSize:self.collectionView.frame.size];
            self.coverFlowLayout.minimumLineSpacing = -70;
            self.coverFlowLayout.itemSize = CGSizeMake(CELL_SIZE.width * 1.8, CELL_SIZE.height * 1.8);
        }
        //[self.collectionView setCollectionViewLayout:self.coverFlowLayout animated:TRUE];
        self.collectionView.collectionViewLayout = self.coverFlowLayout;
        [self.coverFlowLayout invalidateLayout];
    }
}

- (IBAction)handleRollItemSegmentControlValueChange:(UISegmentedControl *)sender {
    CameraRollSegment rollItemSegment = CameraRollSegmentNone;
    if (sender.selectedSegmentIndex == 0) {
        rollItemSegment = CameraRollSegmentAll;
    } else if (sender.selectedSegmentIndex == 1) {
        rollItemSegment = CameraRollSegmentPhoto;
    } else if (sender.selectedSegmentIndex == 2) {
        rollItemSegment = CameraRollSegmentVideo;
    }
    
    [self filterCameraRollItemsBySegment:rollItemSegment];
    [self.collectionView performBatchUpdates:^{
        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    } completion:Nil];
}

//
// collection view data source
//
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.currentViewingCameraRollItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CameraRollItemCell* cell = (CameraRollItemCell*)[collectionView dequeueReusableCellWithReuseIdentifier:@"cameraRollItemCell" forIndexPath:indexPath];
    // config cell
    [cell prepareForReuse];
    CameraRollItem* cameraRollItem = [self.currentViewingCameraRollItems objectAtIndex:indexPath.row];
    [self configCameraRollCell:cell WithModel:cameraRollItem];
    
    return cell;
}

//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
//    NSArray* segmentCameraRollItems = [self filterCameraRollItemBySegment];
//    CameraRollItem* cameraRollItem = [segmentCameraRollItems objectAtIndex:indexPath.item];
//    if (cameraRollItem && cameraRollItem.thumbnailImage) {
//        float thumbnailAspectRatio = cameraRollItem.thumbnailImage.size.width / cameraRollItem.thumbnailImage.size.height;
//        if (thumbnailAspectRatio > 1) {
//            return CGSizeMake(CELL_SIZE.width, CELL_SIZE.width / thumbnailAspectRatio);
//        } else if (thumbnailAspectRatio < 1) {
//            return CGSizeMake(CELL_SIZE.height * thumbnailAspectRatio, CELL_SIZE.height);
//        }
//        
//    }
//    return CELL_SIZE;
//}



@end
