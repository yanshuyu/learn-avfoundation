//
//  NSURL+SYAddition.m
//  04_videoCapture
//
//  Created by sy on 2019/8/1.
//  Copyright © 2019 sy. All rights reserved.
//

#import "NSURL+SYAddition.h"

@implementation NSURL (SYAddition)

+ (instancetype)uniqueFileURLAtDirectory:(NSString *)directory FileExtension:(NSString *)extension {
    NSString* uniqueFileName = [NSString stringWithFormat:@"%@.%@", [NSUUID new].UUIDString, extension];
    NSString* urlPathString = [directory stringByAppendingPathComponent:uniqueFileName];
    return [NSURL fileURLWithPath:urlPathString];
}

@end
