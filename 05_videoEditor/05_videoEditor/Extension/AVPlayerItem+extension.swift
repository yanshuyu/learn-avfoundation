//
//  AVPlayerItem+extension.swift
//  05_videoEditor
//
//  Created by sy on 2020/7/2.
//  Copyright © 2020 sy. All rights reserved.
//

import AVFoundation


extension AVPlayerItem {
    private static var animationLayerKey: Int = 0
    var animationLayer: CALayer? {
        get {
            if let layer =  objc_getAssociatedObject(self,&AVPlayerItem.animationLayerKey) as? CALayer {
                return layer
            }
            return nil
        }
        
        set {
            objc_setAssociatedObject(self,
                                     &AVPlayerItem.animationLayerKey,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

