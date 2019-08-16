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

#define CELL_SIZE CGSizeMake(122, 122)


typedef enum : NSUInteger {
    CameraRollSegmentAll,
    CameraRollSegmentPhoto,
    CameraRollSegmentVideo,
    CameraRollSegmentNone,
} CameraRollSegment;


@interface CameraRollBrowserViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;

@property (strong, nonatomic) NSMutableArray<CameraRollItem*>* cameraRollItems;
@property (nonatomic) CameraRollSegment cameraRollSegment;

@end

@implementation CameraRollBrowserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
    CameraRollManager* cameraRollMgr = [CameraRollManager new];
    self.cameraRollItems = [NSMutableArray arrayWithArray:[cameraRollMgr fetchCameraRollItems]];
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.cameraRollItems.count-1 inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:FALSE];
}


- (void)setupView {
    self.cameraRollSegment = CameraRollSegmentAll;
    self.navigationController.navigationBar.hidden = TRUE;
    
    UIVisualEffectView* buttonBlurOverlayView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    buttonBlurOverlayView.frame = self.closeButton.frame;
    [self.view insertSubview:buttonBlurOverlayView belowSubview:self.closeButton];
    self.closeButton.layer.cornerRadius = self.closeButton.bounds.size.width * 0.5;
    self.closeButton.layer.masksToBounds = TRUE;
    buttonBlurOverlayView.layer.cornerRadius = buttonBlurOverlayView.bounds.size.width * 0.5;
    buttonBlurOverlayView.layer.masksToBounds = TRUE;
    
    UIVisualEffectView* segmentBlurOverlayView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    segmentBlurOverlayView.frame = self.segmentControl.frame;
    [self.view insertSubview:segmentBlurOverlayView belowSubview:self.segmentControl];
    segmentBlurOverlayView.layer.cornerRadius = 4;
    segmentBlurOverlayView.layer.masksToBounds = TRUE;
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    UICollectionViewFlowLayout* flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.minimumLineSpacing = 4;
    flowLayout.minimumInteritemSpacing = 4;
    flowLayout.itemSize = CELL_SIZE;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 40, 0);
    self.collectionView.collectionViewLayout = flowLayout;
    self.collectionView.backgroundColor = [UIColor blackColor];
    self.collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    
//    CGFloat bottomOffset = self.collectionView.contentSize.height - self.collectionView.bounds.size.height;
//    [self.collectionView setContentOffset:CGPointMake(0, bottomOffset) animated:FALSE];
}

- (void)configCameraRollCell:(CameraRollItemCell*)cell WithModel:(CameraRollItem*)item {
    if (item.mediaType == PHAssetMediaTypeImage) {
        
    } else if (item.mediaType == PHAssetMediaTypeVideo) {
        cell.durationLable.text = [NSString stringWithFormat:@"%02d:%02d", ((int)item.duration)/60,((int)item.duration)%60];
        cell.durationLable.hidden = FALSE;
        cell.playImageView.hidden = FALSE;
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

- (NSArray<CameraRollItem*>*) filterCameraRollItemBySegment {
    NSMutableArray<CameraRollItem*>* result = [NSMutableArray array];
    if (self.cameraRollSegment == CameraRollSegmentAll) {
        result = self.cameraRollItems;
    } else if (self.cameraRollSegment == CameraRollSegmentPhoto) {
        [self.cameraRollItems enumerateObjectsUsingBlock:^(CameraRollItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.mediaType == PHAssetMediaTypeImage) {
                [result addObject:obj];
            }
        }];
    } else if (self.cameraRollSegment == CameraRollSegmentVideo) {
        [self.cameraRollItems enumerateObjectsUsingBlock:^(CameraRollItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.mediaType == PHAssetMediaTypeVideo) {
                [result addObject:obj];
            }
        }];
    }
    
    return result;
}

- (void)updateCameraRollSegment:(NSInteger)index {
    if (index == 0) {
        self.cameraRollSegment = CameraRollSegmentAll;
    } else if (index == 1) {
        self.cameraRollSegment = CameraRollSegmentPhoto;
    } else if (index == 2) {
        self.cameraRollSegment = CameraRollSegmentVideo;
    }
}

- (BOOL)prefersStatusBarHidden {
    return TRUE;
}

- (IBAction)handleCloseButtonTap:(UIButton *)sender {
    [self dismissViewControllerAnimated:TRUE completion:nil];
}

- (IBAction)handleSegmentControllTap:(UISegmentedControl *)sender {
    [self updateCameraRollSegment:sender.selectedSegmentIndex];
    [self.collectionView performBatchUpdates:^{
        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    } completion:Nil];
}

//
// collection view data source
//
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSArray* segmentCameraRollItems = [self filterCameraRollItemBySegment];
    if (segmentCameraRollItems) {
        return segmentCameraRollItems.count;
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CameraRollItemCell* cell = (CameraRollItemCell*)[collectionView dequeueReusableCellWithReuseIdentifier:@"cameraRollItemCell" forIndexPath:indexPath];
    // config cell
    [cell prepareForReuse];
    CameraRollItem* cameraRollItem = [[self filterCameraRollItemBySegment] objectAtIndex:indexPath.row];
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
