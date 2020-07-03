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
    private var playerLayer = AVPlayerLayer()
    
    private var animationSyncLayer = AVSynchronizedLayer()
    
    private var animationLayer: CALayer?
    
    public var player: AVPlayer? {
        set {
            self.playerLayer.player = newValue
            self.animationSyncLayer.playerItem = newValue?.currentItem
            addAnimations(newValue?.currentItem?.animationLayer)
        }
        get {
            return self.playerLayer.player
        }
    }
    
    public var isReadyForDisplay: Bool {
        return self.playerLayer.isReadyForDisplay
    }
    
    public var gravity: AVLayerVideoGravity {
        set {
            self.playerLayer.videoGravity = newValue
        }
        get {
            return self.playerLayer.videoGravity
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        selfInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        selfInit()
    }
    
    
    private func selfInit() {
        self.layer.addSublayer(self.playerLayer)
        self.layer.addSublayer(self.animationSyncLayer)
        self.backgroundColor = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.playerLayer.frame = self.bounds
        //self.animationSyncLayer.frame = self.bounds
        //self.animationSyncLayer.backgroundColor = UIColor.green.cgColor
        self.animationLayer?.frame = self.bounds
        //self.animationSyncLayer.backgroundColor = UIColor.red.cgColor
    }
    
    private func addAnimations(_ animLayer: CALayer?) {
        self.animationLayer?.removeFromSuperlayer()
        self.animationSyncLayer.sublayers?.removeAll()
        self.animationLayer = animLayer
        if let _ = animLayer {
            self.animationSyncLayer.addSublayer(animLayer!)
            self.layer.addSublayer(animLayer!)
            self.setNeedsLayout()
        }
    }
}
