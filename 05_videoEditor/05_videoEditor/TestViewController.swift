//
//  TestViewController.swift
//  05_videoEditor
//
//  Created by sy on 2020/5/26.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation

class TestViewController: AVPlayerViewController {
    private var timeLine = VETimeLine()    
    fileprivate var syncGroup: DispatchGroup = DispatchGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let canvas = self.timeLine.canvasProvider as? BasicVanvas {
            canvas.mode = .blurBackground
            canvas.canvasBlurness = 14
        }
        loadMainTrackItems()
        //loadOverlayTrackItems()
        //loadAudioTrackItems()
        self.syncGroup.notify(queue: DispatchQueue.main) { [weak self] in
            self?.testComposition()
        }
    }
    
    func loadMainTrackItems() {
        var url: URL
        var trackItem: TransitionableVideoTrackItem
        
        url = Bundle.main.url(forResource: "cute", withExtension: "mp4")!
        trackItem = TransitionableVideoTrackItem(resource: AVAssetResource(url: url))
        trackItem.videoTransition = VideoTransitionPageCurl()
        trackItem.videoTransition?.duration = CMTime(seconds: 2, preferredTimescale: 600)
        self.timeLine.addVideoItem(trackItem)
        self.syncGroup.enter()
        trackItem.prepare(progressHandler: nil) {(status, error) in
            if status != .availdable {
                print("resource unavailable, url: \(trackItem.resource!.resourceURL?.absoluteString ?? "nil")")
            }
            self.syncGroup.leave()
        }
        
        
        
        url = Bundle.main.url(forResource: "03_nebula", withExtension: "mp4")!
        trackItem = TransitionableVideoTrackItem(resource: AVAssetResource(url: url))
        trackItem.videoTransition = VideoTransitionPush()
        trackItem.videoTransition?.duration = CMTime(seconds: 2, preferredTimescale: 600)
        self.timeLine.addVideoItem(trackItem)
        self.syncGroup.enter()
        trackItem.prepare(progressHandler: nil) {(status, error) in
            if status != .availdable {
                print("resource unavailable, url: \(trackItem.resource!.resourceURL?.absoluteString ?? "nil")")
            }
            self.syncGroup.leave()
        }
        

        
        url = Bundle.main.url(forResource: "02_blackhole", withExtension: "mp4")!
        trackItem = TransitionableVideoTrackItem(resource: AVAssetResource(url: url))
        trackItem.videoTransition = VideoTransitionDissolve()
        trackItem.videoTransition?.duration = CMTime(seconds: 2, preferredTimescale: 600)
        if let videoConfig = trackItem.videoConfiguration as? BasicVideoConfiguration {
            videoConfig.filter = CIFilter(name: "CIPhotoEffectMono")
        }
        self.timeLine.addVideoItem(trackItem)
        self.syncGroup.enter()
        trackItem.prepare(progressHandler: nil) {(status, error) in
            if status != .availdable {
                print("resource unavailable, url: \(trackItem.resource!.resourceURL?.absoluteString ?? "nil")")
            }
            self.syncGroup.leave()
        }
        
        
        
        url = Bundle.main.url(forResource: "04_quasar", withExtension: "mp4")!
        trackItem = TransitionableVideoTrackItem(resource: AVAssetResource(url: url))
        trackItem.videoTransition = VideoTransitionSwipe()
        trackItem.videoTransition?.duration = CMTime(seconds: 2, preferredTimescale: 600)
        self.timeLine.addVideoItem(trackItem)
        self.syncGroup.enter()
        trackItem.prepare(progressHandler: nil) {(status, error) in
            if status != .availdable {
                print("resource unavailable, url: \(trackItem.resource!.resourceURL?.absoluteString ?? "nil")")
            }
            self.syncGroup.leave()
        }
    }
    
    func loadOverlayTrackItems() {
        let url = Bundle.main.url(forResource: "853", withExtension: "mp4")!
        let overlayItem = VideoTrackItem(resource: AVAssetResource(url: url))
        self.timeLine.addOverlayItem(overlayItem, at: .zero)
       
        self.syncGroup.enter()
        overlayItem.prepare(progressHandler: nil) { (status, error) in
            self.syncGroup.leave()
            if status != .availdable {
                print("resource unavailable, url: \(overlayItem.resource!.resourceURL?.absoluteString ?? "nil")")
                return
            }
            overlayItem.selectedTimeRange = CMTimeRange(start: .zero, duration: CMTimeMakeWithSeconds(5, preferredTimescale: 600))
        }
    }
    
    func loadAudioTrackItems() {
        let url = Bundle.main.url(forResource: "01 Star Gazing", withExtension: "m4a")!
        
        let audioItem = AudioTrackItem(resource: AVAssetResource(url: url))
        self.timeLine.addAudioItem(audioItem)
        self.syncGroup.enter()
        audioItem.prepare(progressHandler: nil) { [weak self] (resourceStatus, error) in
            if resourceStatus != .availdable {
                print("resource unavailable, url: \(audioItem.resource!.resourceURL?.absoluteString ?? "nil")")
            }
            self?.syncGroup.leave()
        }
    }
    
    func testComposition() {
        //updateTrackItems()
        self.timeLine.updateTimeRanges()
        let compositionGenerator = VECompositionGenerator(timeLine: self.timeLine)
        if let playerItem = compositionGenerator.buildPlayerItem() {
             print(compositionGenerator.debugDescription)
            self.player = AVPlayer(playerItem: playerItem)
            self.player?.play()
        }
       
    }
    
    
}
