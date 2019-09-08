//
//  ContentManager.h
//  04_videoCapture
//
//  Created by sy on 2019/8/3.
//  Copyright © 2019 sy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CIContext;

@interface ContextManager : NSObject

@property(strong, nonatomic, readonly) CIContext* shareCIContext;
@property(strong, nonatomic, readonly) EAGLContext* shareGLContext;

+ (instancetype)shareInstance;


@end

NS_ASSUME_NONNULL_END
