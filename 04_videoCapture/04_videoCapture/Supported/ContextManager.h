//
//  ContentManager.h
//  04_videoCapture
//
//  Created by sy on 2019/8/3.
//  Copyright © 2019 sy. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@class CIContext;

@interface ContextManager : NSObject

@property (strong, nonatomic) CIContext* shareCIContext;

+ (instancetype)shareInstance;

@end

NS_ASSUME_NONNULL_END
