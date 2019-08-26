//
//  BuildInFilterLibrary.m
//  04_videoCapture
//
//  Created by sy on 2019/8/5.
//  Copyright © 2019 sy. All rights reserved.
//

#import "BuildInFilterLibrary.h"
#import <CoreImage/CoreImage.h>

@interface BuildInFilterLibrary ()

@property (strong, nonatomic) NSMutableDictionary* filters;

@end


@implementation BuildInFilterLibrary

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.filters = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (instancetype)shareInstance {
    static BuildInFilterLibrary* uniqueInstance;
    static dispatch_once_t once_flag;
    dispatch_once(&once_flag, ^{
        uniqueInstance = [BuildInFilterLibrary new];
    });
    
    return uniqueInstance;
}

- (NSArray *)filterNamesInCategory:(NSString *)category {
    return [CIFilter filterNamesInCategory:category];
}

- (CIFilter *)filterWithName:(NSString *)name InCategory:(NSString *)category {
    // find if it is already in library
    CIFilter* result = [self getFilterWithName:name InCategory:category];
    if (result) {
        return result;
    }
    
    //not in library, try to create one
    if ([[self filterNamesInCategory:category] containsObject:name]) {
        return [self addFilterWithName:name InCategory:category];
    }
    
    return Nil;
}


- (CIFilter*)getFilterWithName:(NSString*)name InCategory:(NSString*)category {
    NSDictionary* filterGroup = [self.filters objectForKey:category];
    if (filterGroup) {
        return [filterGroup objectForKey:name];
    }
    
    return Nil;
}

- (CIFilter*)addFilterWithName:(NSString*)name InCategory:(NSString*)category {
    // create filter
    CIFilter* filter = [CIFilter filterWithName:name];
    if (filter) {
        NSMutableDictionary* filterGroup = [self.filters objectForKey:category];
        //create filter group
        if (!filterGroup) {
            filterGroup = [NSMutableDictionary dictionary];
            [self.filters setValue:filterGroup forKey:category];
        }
        
        [filterGroup setValue:filter forKey:name];
        
        return filter;
    }
    
    return Nil;
}

- (void)reset {
    self.filters = [NSMutableDictionary dictionary];
}

@end
