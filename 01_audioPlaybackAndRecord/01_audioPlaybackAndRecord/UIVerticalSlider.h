//
//  UIVerticalSlider.h
//  01_audioPlaybackAndRecord
//
//  Created by sy on 2019/5/10.
//  Copyright © 2019 sy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

IB_DESIGNABLE
@interface UIVerticalSlider : UIView

@property UISlider* _slider;
@property (nonatomic, getter=getMinVal, setter=setMinVal:) IBInspectable CGFloat minVal;
@property (nonatomic, getter=getMaxVal, setter=setMaxVal:) IBInspectable CGFloat maxVal;
@property (nonatomic, getter=getVal, setter=setVal:) IBInspectable CGFloat val;
@property (nonatomic, getter=getContinues, setter=setContinues:) IBInspectable BOOL continues;

@end

NS_ASSUME_NONNULL_END
