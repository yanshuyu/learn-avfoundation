//
//  GLPreviewView.h
//  04_videoCapture
//
//  Created by sy on 2019/9/8.
//  Copyright © 2019 sy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GLPreviewView  : UIView

- (void)renderCIImage:(CIImage*)image;

@end

NS_ASSUME_NONNULL_END
