//
//  CameraRollItemCell.m
//  04_videoCapture
//
//  Created by sy on 2019/8/12.
//  Copyright © 2019 sy. All rights reserved.
//
#import "CameraRollItemCell.h"


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
    [self prepareForReuse];
}

- (void)prepareForReuse {
    self.thumnailImageView.image = nil;
    self.thumnailImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.durationLable.hidden = TRUE;
    self.liveLable.hidden = TRUE;
    self.cloudeImageView.hidden = TRUE;
    self.playImageView.hidden = TRUE;
}



@end
