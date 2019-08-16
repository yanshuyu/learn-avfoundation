//
//  CameraRollItemCell.m
//  04_videoCapture
//
//  Created by sy on 2019/8/12.
//  Copyright © 2019 sy. All rights reserved.
//
#import "CameraRollItemCell.h"
#import "../Supported/SYCollectionViewCoverFlowLayoutAttributes.h"

// for cover flow layout
@interface CameraRollItemCell ()

@property (strong, nonatomic) UIView* maskView;

@end


@implementation CameraRollItemCell

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setUpView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setUpView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpView];
    }
    return self;
}

- (void)setUpView {
    self.layer.cornerRadius = 4;
    self.layer.masksToBounds = TRUE;
    
    self.maskView = [[UIView alloc] initWithFrame:self.bounds];
    self.maskView.backgroundColor = [UIColor blackColor];
    self.maskView.alpha = 0;
    self.maskView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentView addSubview:self.maskView];
    
    [self prepareForReuse];
}

- (void)prepareForReuse {
    self.thumnailImageView.image = nil;
    self.thumnailImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.durationLable.hidden = TRUE;
    self.liveLable.hidden = TRUE;
    self.cloudeImageView.hidden = TRUE;
    self.playImageView.hidden = TRUE;
    self.maskView.alpha = 0;
    self.maskView.frame = self.bounds;
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    [super applyLayoutAttributes:layoutAttributes];
    if ([layoutAttributes isKindOfClass:[SYCollectionViewCoverFlowLayoutAttributes class]]
        && layoutAttributes.representedElementCategory == UICollectionElementCategoryCell) {
        SYCollectionViewCoverFlowLayoutAttributes* coverFlowLayoutAttributes = (SYCollectionViewCoverFlowLayoutAttributes*)layoutAttributes;
        self.layer.shouldRasterize = coverFlowLayoutAttributes.shouldRaster;
        self.maskView.alpha = coverFlowLayoutAttributes.maskAlpha;
    }
   
}

@end
