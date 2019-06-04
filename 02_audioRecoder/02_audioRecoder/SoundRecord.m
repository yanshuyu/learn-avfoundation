//
//  SoundRecord.m
//  02_audioRecoder
//
//  Created by sy on 2019/5/24.
//  Copyright © 2019 sy. All rights reserved.
//

#import "SoundRecord.h"

#define KENCODE_NAME @"name"
#define KENCODE_URL @"url"
#define KENCODE_PATH @"path"
#define KENCODE_DATE @"createDate"


@implementation SoundRecord

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)init {
    return [self initWithName:nil Path:nil];
}

- (instancetype)initWithName:(NSString* _Nullable)name Path:(NSString* _Nullable)path {
    self = [super init];
    if (self) {
        _name = name;
        _path = path;
        _createdDate = [NSDate date];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
//        _name = (NSString*)[coder decodeObjectForKey:KENCODE_NAME];
//        _url = (NSURL*)[coder decodeObjectForKey:KENCODE_URL];
//        _createdDate = (NSDate*)[coder decodeObjectForKey:KENCODE_DATE];
        _name = [coder decodeObjectOfClass:[NSString class] forKey:KENCODE_NAME];
        _path = [coder decodeObjectOfClass:[NSString class] forKey:KENCODE_PATH];
        _createdDate = [coder decodeObjectOfClass:[NSDate class] forKey:KENCODE_DATE];
    }
    return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    [aCoder encodeObject:_name forKey:KENCODE_NAME];
    [aCoder encodeObject:_path forKey:KENCODE_PATH];
    [aCoder encodeObject:_createdDate forKey:KENCODE_DATE];
}


- (NSString*)dateString {
    NSDateFormatter *formatter = [self dateFormatterWithFormat:@"MMddyyyy"];
    return [formatter stringFromDate:self.createdDate];
}

- (NSString*)timeString {
    NSDateFormatter *formatter = [self dateFormatterWithFormat:@"HHmmss"];
    return [formatter stringFromDate:self.createdDate];
}

- (NSDateFormatter*)dateFormatterWithFormat:(NSString*)fmt {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    NSString *format = [NSDateFormatter dateFormatFromTemplate:fmt options:0 locale:[NSLocale currentLocale]];
    [formatter setDateFormat:format];
    return formatter;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"SoundRecord: [ name = %@, path = %@, date = %@]", self.name, self.path, self.createdDate];
}


@end
