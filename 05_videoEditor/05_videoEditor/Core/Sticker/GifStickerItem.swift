//
//  GifStickerItem.swift
//  05_videoEditor
//
//  Created by sy on 2020/7/2.
//  Copyright © 2020 sy. All rights reserved.
//

import UIKit
import CoreMedia


class GifStickerItem: StickerTrackItem {
    var url: URL?
    var name: String?
    
    override init(url: URL) {
        self.url = url
        super.init()
    }
    
    override init(name: String) {
        self.name = name
        super.init()
    }
    
    required init() {
        super.init()
    }
    
    override func animationLayer(for renderSize: CGSize) -> CALayer {
        guard self.url != nil || self.name != nil else {
            return CALayer()
        }
        
        var gifLayerOption: CALayer?
        
        if self.name != nil {
            gifLayerOption = CALayer.gifLayer(name: self.name!,
                                        animationBeginTime: self.startTimeInTrack.seconds,
                                        removeOnCompletion: false)
        }
        
        if gifLayerOption == nil && self.url != nil {
            gifLayerOption = CALayer.gifLayer(url: self.url!,
                                        animationBeginTime: self.startTimeInTrack.seconds,
                                        removeOnCompletion: false)
        }
        
        guard let gifLayer = gifLayerOption else {
            return CALayer()
        }
        
        
        // content
        gifLayer.contentsGravity = self.contentMode

        // size & position
        gifLayer.position = self.position
        if let transform = self.transform {
            gifLayer.transform = transform
        }

        // apprance
        gifLayer.opacity = Float(self.opacity)
        gifLayer.borderWidth = CGFloat(self.borderWidth)
        gifLayer.borderColor = self.borderColor?.cgColor
        
        // visible animation
        //AnimationFactory.share.createVisibleAnimations(for: self.timeRangeInTrack, opacity: self.opacity).forEach({gifLayer.add($0, forKey: nil)})
        
        // in, out, loop animation
//        switch self.inAnimationType {
//            case .fadeIn:
//                let timeRange = CMTimeRange(start: self.startTimeInTrack, duration: self.inAnimationDuration)
//                let fadeIn = AnimationFactory.share.createOpacityAnimation(for: timeRange, opacity: self.opacity)
//                gifLayer.add(fadeIn, forKey: nil)
//                break
//
//            default:
//                break
//        }
//
//        switch self.outAnimationType {
//            case .fadeOut:
//                let timeRange = CMTimeRange(start: CMTimeSubtract(self.timeRangeInTrack.end, self.outAnimationDuration), duration: self.outAnimationDuration)
//                let fadeOut = AnimationFactory.share.createOpacityAnimation(for: timeRange, opacity: 0)
//                gifLayer.add(fadeOut, forKey: nil)
//                break
//
//            default:
//                break
//        }
        
        
        return gifLayer
    }
}

