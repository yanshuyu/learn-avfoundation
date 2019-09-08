//
//  ContentManager.m
//  04_videoCapture
//
//  Created by sy on 2019/8/3.
//  Copyright © 2019 sy. All rights reserved.
//

#import "ContextManager.h"
#import <CoreImage/CoreImage.h>

@interface ContextManager ()

@property(strong, nonatomic, readwrite) CIContext* shareCIContext;
@property(strong, nonatomic, readwrite) EAGLContext* shareGLContext;


@end

@implementation ContextManager

- (instancetype)initContexts {
    self = [super init];
    if (self)
    {
        self.shareGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
        self.shareCIContext = [CIContext contextWithEAGLContext:self.shareGLContext];
    }
    return  self;
}

+ (instancetype)shareInstance {
    static ContextManager* uniqueInstance;
    static dispatch_once_t callOnceFlag;
    dispatch_once(&callOnceFlag, ^{
        uniqueInstance = [[ContextManager alloc] initContexts];
    });
 
    
    return uniqueInstance;
}

@end
