//
//  VEVideoCompositionLayerInstraction.swift
//  05_videoEditor
//
//  Created by sy on 2020/6/22.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation
import CoreImage

class VEVideoCompositionLayerInstruction: VideoEffectProvider {
    var trackID: CMPersistentTrackID
    
    var videoProvider: VideoProvider
    
    var videoTransition: VideoTransition? {
        if let transitionProvider = self.videoProvider as? TransitionableVideoProvider {
            return transitionProvider.videoTransition
        }
        return nil
    }
    
    init(trackID: CMPersistentTrackID, videoProvider: VideoProvider) {
        self.trackID = trackID
        self.videoProvider = videoProvider
    }
    
    
    func applyEffect(to frame: CIImage, renderSize: CGSize, atTime: CMTime) -> CIImage {
        return self.videoProvider.applyEffect(to: frame, renderSize: renderSize, atTime: atTime)
    }
    
    
}

