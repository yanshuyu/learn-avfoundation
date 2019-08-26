//
//  BuildInFilterLibrary.h
//  04_videoCapture
//
//  Created by sy on 2019/8/5.
//  Copyright © 2019 sy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@class CIFilter;

@interface BuildInFilterLibrary : NSObject
- (instancetype)init;
+ (instancetype)shareInstance;
- (NSArray*)filterNamesInCategory:(NSString*)category;
- (CIFilter*)filterWithName:(NSString*)name InCategory:(NSString*)category;
- (void)reset;
@end

NS_ASSUME_NONNULL_END
