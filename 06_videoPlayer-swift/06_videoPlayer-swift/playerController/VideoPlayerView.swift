//
//  VideoPlayerView.swift
//  06_videoPlayer-swift
//
//  Created by sy on 2020/3/6.
//  Copyright © 2020 sy. All rights reserved.
//

import UIKit
import AVFoundation

class VideoPlayerView: UIView {
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    public var videoLayer: AVPlayerLayer {
        return self.layer as! AVPlayerLayer
    }
    
    public var player: AVPlayer? {
        set {
            self.videoLayer.player = newValue
        }
        get {
            return self.videoLayer.player
        }
    }
    
    public var isReadyForDisplay: Bool {
        return self.videoLayer.isReadyForDisplay
    }
    
    public var gravity: AVLayerVideoGravity {
        set {
            self.videoLayer.videoGravity = newValue
        }
        get {
            return self.videoLayer.videoGravity
        }
    }
}
