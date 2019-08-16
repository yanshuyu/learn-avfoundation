//
//  SYCollectionViewCoverFlowLayoutAttributes.m
//  04_videoCapture
//
//  Created by sy on 2019/8/16.
//  Copyright © 2019 sy. All rights reserved.
//

#import "SYCollectionViewCoverFlowLayoutAttributes.h"

@implementation SYCollectionViewCoverFlowLayoutAttributes

- (instancetype)copyWithZone:(NSZone *)zone {
    SYCollectionViewCoverFlowLayoutAttributes* copy = [super copyWithZone:zone];
    copy.shouldRaster = self.shouldRaster;
    copy.maskAlpha = self.maskAlpha;
    return  copy;
}

- (BOOL)isEqual:(id)object {
    return [super isEqual:object]
    && ((SYCollectionViewCoverFlowLayoutAttributes*)object).shouldRaster == self.shouldRaster
    && ((SYCollectionViewCoverFlowLayoutAttributes*)object).maskAlpha == self.maskAlpha;
}

@end
