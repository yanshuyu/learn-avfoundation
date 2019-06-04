//
//  SoundRecord.h
//  02_audioRecoder
//
//  Created by sy on 2019/5/24.
//  Copyright © 2019 sy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SoundRecord : NSObject <NSCoding, NSSecureCoding>

@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) NSString* path;
@property (nonatomic, readonly) NSDate* createdDate;

- (instancetype)initWithName:(NSString* _Nullable)name Path:(NSString* _Nullable)path;
- (NSString*)dateString;
- (NSString*)timeString;

@end

NS_ASSUME_NONNULL_END
