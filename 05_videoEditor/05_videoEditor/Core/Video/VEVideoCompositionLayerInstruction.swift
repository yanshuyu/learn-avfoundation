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
    
    var trackInfo: ResourceTrackInfo?
    
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
        var transformedFrame = frame
        if let trackInfo = self.trackInfo {
            transformedFrame = transformedFrame.transformed(by: trackInfo.preferredTransform)
        }
        return self.videoProvider.applyEffect(to: transformedFrame, renderSize: renderSize, atTime: atTime)
    }
    
    
}

