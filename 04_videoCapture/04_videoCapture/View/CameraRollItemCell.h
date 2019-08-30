//
//  CameraRollItemCell.h
//  04_videoCapture
//
//  Created by sy on 2019/8/12.
//  Copyright © 2019 sy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CameraRollItemCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *thumnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *durationLable;
@property (weak, nonatomic) IBOutlet UILabel *liveLable;
@property (weak, nonatomic) IBOutlet UIImageView *cloudeImageView;

@end

NS_ASSUME_NONNULL_END
