//
//  VideoTransition.swift
//  05_videoEditor
//
//  Created by sy on 2020/6/21.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation
import CoreImage

protocol VideoTransition: class {
    var identifier: String { get }
    var duration: CMTime { set get }
    
    func renderTransition(from sourceFrame: CIImage, to destinationFrame: CIImage, tweening: Float) -> CIImage
}

class VideoTransitionCutoff: VideoTransition {
    var identifier: String {
        return String(describing: self)
    }
    
    var duration: CMTime
    
    convenience init() {
        self.init(duration: CMTimeMakeWithSeconds(1, preferredTimescale: 600))
    }
    
    init(duration: CMTime) {
        self.duration = duration
    }
    
    func renderTransition(from sourceFrame: CIImage, to destinationFrame: CIImage, tweening: Float) -> CIImage {
        return destinationFrame
    }
    
    
}
