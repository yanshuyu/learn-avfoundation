//
//  ViewController.swift
//  06_videoPlayer-swift
//
//  Created by sy on 2020/3/6.
//  Copyright © 2020 sy. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var player: VideoPlayer = VideoPlayer(contentOfURL: nil)
    let testURL = URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4")
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.view.addSubview(self.player.view)
//        self.player.view.frame = self.view.bounds
//        self.player.delegate = self
//        self.player.replace(withContentOfURL: self.testURL!)
//        self.player.videoGravity = .resizeAspectFill
//
//        if let subTitleSelGrp = self.player.mediaSelectionGroupForMediaCharacteristic(.legible) {
//            print("sub title selection options: \(subTitleSelGrp.options)")
//        }
//
//        self.player.play()
    }
    
    override func viewDidLayoutSubviews() {
        self.player.view.frame = self.view.bounds
    }
    
//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        return [.landscapeLeft, .landscapeRight]
//    }
}


extension ViewController: VideoPlayerDelegate {
    func videoPlayerIsReadyToPlay(_ player: VideoPlayer) {
        print("ready to play.")
    }
    
    func videoPlayerIsFailed(_ player: VideoPlayer, with error: Error?) {
        print("load video fail. error: \(error ?? nil)")
    }
    
    func videoPlayer(_ player: VideoPlayer, statusDidChange to: VideoPlayer.PlayerStatus) {
        switch to {
            case .playing:
                print("playing.")
                break
            case .waiting(let reason):
                print("waiting for reason: \(reason)")
                break
            case .pause(let reason):
                print("pause for reason: \(reason)")
                break
            default:
                break
        }
    }
    
    func videoPlayer(_ player: VideoPlayer, timeDidChange to: Double) {
        print("play header time point: \(to)")
    }
    
    func videoPlayer(_ player: VideoPlayer, loadedTimeRangeDidChange to: [(Double, Double)]) {
        print("loaded time range: \(to)")
    }
}

