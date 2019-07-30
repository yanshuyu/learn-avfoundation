//
//  VideoGestureLayer.h
//  04_videoCapture
//
//  Created by sy on 2019/7/30.
//  Copyright © 2019 sy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class VideoGestureLayer;

@protocol VideoGestureLayerDelegate <NSObject>

@optional
- (void)videoGestureLayer:(VideoGestureLayer*)layer TapToFocusAndExposureAtLayerPoint:(CGPoint)point;
- (void)videoGestureLayer:(VideoGestureLayer*)layer TapToResetFocusAndExposureAtLayerPoint:(CGPoint)tapPoint RecommandedPoint:(CGPoint)recommandedpoint;
- (void)videoGestureLayer:(VideoGestureLayer*)layer BeginCameraZoom:(CGFloat)scale;
- (void)videoGestureLayer:(VideoGestureLayer*)layer CameraZoomingWithDetalScale:(CGFloat)scale;
- (void)videoGestureLayer:(VideoGestureLayer*)layer DidFinishCameraZoom:(CGFloat)scale;

@end

@interface VideoGestureLayer : UIView

@property (weak, nonatomic) id<VideoGestureLayerDelegate> delegate;
@property (assign, nonatomic) BOOL tapToFocusAndExposureEnabled;
@property (nonatomic) BOOL pinchToZoomCameraEnabled;

@end

NS_ASSUME_NONNULL_END
