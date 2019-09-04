//
//  UIImage+SYAddtion.h
//  04_videoCapture
//
//  Created by sy on 2019/9/4.
//  Copyright © 2019 sy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (SYAddtion)
+ (instancetype)imageWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;
@end

NS_ASSUME_NONNULL_END
