//
//  TestViewController.swift
//  05_videoEditor
//
//  Created by sy on 2020/5/26.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVKit

class TestViewController: AVPlayerViewController {
    private var timeLine = VETimeLine()
    private var videoLoadedCounter = 0
    private var audioLoaderCounter = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        loadMainTrackItems(urls: [Bundle.main.url(forResource: "01_nebula", withExtension: "mp4")!,
                              Bundle.main.url(forResource: "02_blackhole", withExtension: "mp4")!,
                              Bundle.main.url(forResource: "03_nebula", withExtension: "mp4")!,
                              Bundle.main.url(forResource: "04_quasar", withExtension: "mp4")!])
    }
    
    func loadMainTrackItems(urls: [URL]) {
        for url in urls {
            let trackItem = TransitionableVideoTrackItem(resource: AVAssetResource(url: url))
            trackItem.prepare(progressHandler: nil) {(status, error) in
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else {
                         return
                     }
                    strongSelf.videoLoadedCounter += 1
                }
                
                if status == .availdable {
                    DispatchQueue.main.async { [weak self] in
                        if let strongSelf = self {
                            trackItem.transitionDuration = CMTimeMakeWithSeconds(1, preferredTimescale: 600)
                            strongSelf.timeLine.addVideoItem(trackItem)
                            
                            if strongSelf.videoLoadedCounter >= urls.count {
                                strongSelf.loadAudioTrackItems()
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    func loadAudioTrackItems() {
        let url = Bundle.main.url(forResource: "01 Star Gazing", withExtension: "m4a")!
        
        let audioItem = AudioTrackItem(resource: AVAssetResource(url: url))
        audioItem.prepare(progressHandler: nil) { [weak self] (resourceStatus, error) in
            if resourceStatus == .availdable, let strongSelf = self {
                audioItem.selectedTimeRange = CMTimeRangeMake(start: .zero, duration: CMTimeMakeWithSeconds(9, preferredTimescale: 600))
                strongSelf.timeLine.addAudioItem(audioItem)
                DispatchQueue.main.async {
                    strongSelf.testComposition()
                }
            }
        }
    }
    
    func testComposition() {
        //updateTrackItems()
        self.timeLine.reloadTimeRanges()
        let compositionGenerator = VECompositionGenerator(timeLine: self.timeLine)
        if let playerItem = compositionGenerator.buildPlayerItem() {
            self.player = AVPlayer(playerItem: playerItem)
            self.player?.play()
        }
        print(compositionGenerator.debugDescription)
    }
    
    
}
