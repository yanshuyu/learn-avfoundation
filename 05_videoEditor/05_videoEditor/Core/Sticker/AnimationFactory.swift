//
//  AnimationFactory.swift
//  05_videoEditor
//
//  Created by sy on 2020/7/2.
//  Copyright © 2020 sy. All rights reserved.
//

import CoreMedia
import UIKit

class AnimationFactory {
    static var share: AnimationFactory = AnimationFactory()
    
    func createVisibleAnimations(for timeRange: CMTimeRange, opacity: Float = 1) -> [CABasicAnimation] {
        let showAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        let hideAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        let frameDuration = 1.0
        
        showAnimation.fromValue = 0
        showAnimation.toValue = opacity
        showAnimation.beginTime = timeRange.start.seconds - frameDuration
        showAnimation.duration = frameDuration
        showAnimation.fillMode = .forwards
        showAnimation.isRemovedOnCompletion = false
        
        hideAnimation.toValue = 0
        hideAnimation.beginTime = timeRange.end.seconds
        hideAnimation.duration = frameDuration
        hideAnimation.fillMode = .forwards
        hideAnimation.isRemovedOnCompletion = false
        
        return [showAnimation, hideAnimation]
    }
    
    
    func createOpacityAnimation(for timeRange: CMTimeRange, opacity: Float, smoothInterpolation: Bool = true) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        animation.toValue = opacity
        animation.beginTime = timeRange.start.seconds
        animation.duration = timeRange.duration.seconds
        animation.fillMode = .both
        animation.isRemovedOnCompletion = false
        if smoothInterpolation {
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        }
        
        return animation
    }
}
