//
//  NSURL+SYAddition.h
//  04_videoCapture
//
//  Created by sy on 2019/8/1.
//  Copyright © 2019 sy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (SYAddition)

+(instancetype)uniqueFileURLAtDirectory:(NSString*)directory FileExtension:(NSString*)extension;

@end

NS_ASSUME_NONNULL_END
