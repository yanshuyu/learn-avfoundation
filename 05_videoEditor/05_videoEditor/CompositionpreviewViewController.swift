//
//  CompositionpreviewViewController.swift
//  05_videoEditor
//
//  Created by sy on 2020/7/1.
//  Copyright © 2020 sy. All rights reserved.
//

import UIKit
import AVFoundation

class CompositionPreviewViewController: UIViewController {
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var leftTimeLable: UILabel!
    @IBOutlet weak var rightTimeLable: UILabel!
    
    @IBOutlet weak var progressSlider: UISlider!
    
    private var timeLine: TimeLine = VETimeLine()
    
    private var syncGroup = DispatchGroup()
    
    private var previewPlayer = VideoPlayer()
    
    private var isPlaying = false
    
    private var isSeeking = false
    
    private var isShowingUI = true
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.previewPlayer.view)
        self.view.sendSubviewToBack(self.previewPlayer.view)
        self.previewPlayer.delegate = self
        
        self.view.backgroundColor = nil
        self.playButton.isHidden = true
        self.spinner.startAnimating()
        
        self.progressSlider.addTarget(self, action: #selector(onProgressSliderDragging), for: .touchDragInside)
        self.progressSlider.addTarget(self, action: #selector(onProgressSliderDragging), for: .touchDragOutside)
        self.progressSlider.addTarget(self, action: #selector(onProgressSliderDragEnd), for: .touchUpInside)
        self.progressSlider.addTarget(self, action: #selector(onProgressSliderDragEnd), for: .touchUpOutside)
        
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onMainUITap)))
        
        if let canvas = self.timeLine.canvasProvider as? BasicVanvas {
            canvas.mode = .blurBackground
        }
        
//        if let testGifLayer = CALayer.gifLayer(name: "391910250_JACK_O_LANTERN_400px", animationBeginTime: 0, removeOnCompletion: false) {
//            let gifView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: testGifLayer.bounds.width, height: testGifLayer.bounds.height)))
//            gifView.layer.addSublayer(testGifLayer)
//            testGifLayer.frame = gifView.bounds
//            self.view.addSubview(gifView)
//        }
        
        loadTestComposition {
            self.spinner.stopAnimating()
            self.spinner.isHidden = true
            self.playButton.isHidden = false
            
            self.timeLine.updateTimeRanges()
            let compositionGenerator = VECompositionGenerator(timeLine: self.timeLine)
            
            if let previewItem = compositionGenerator.buildPlayerItem() {
                print(compositionGenerator)
                self.previewPlayer.replace(withPlayItem: previewItem)
            } else {
                let alertVC = UIAlertController(title: "Error", message: "Failed to build player item", preferredStyle: .alert)
                let ok = UIAlertAction(title: "ok", style: .default, handler: nil)
                alertVC.addAction(ok)
                self.present(alertVC, animated: true, completion: nil)
            }
        }
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewPlayer.view.frame = self.view.bounds
    }
    
    @IBAction func onPlayButtonTap(_ sender: UIButton) {
        if self.isPlaying {
            self.previewPlayer.pause()
        } else {
            self.previewPlayer.play()
        }
        self.isPlaying = !self.isPlaying
        self.playButton.isSelected = self.isPlaying
    }
    
    @objc func onMainUITap() {
        self.isShowingUI = !self.isShowingUI
        self.navigationController?.setNavigationBarHidden(!self.isShowingUI, animated: true)
        self.leftTimeLable.isHidden = !self.isShowingUI
        self.rightTimeLable.isHidden = !self.isShowingUI
        self.progressSlider.isHidden = !self.isShowingUI
        self.playButton.isHidden = !self.isShowingUI
    }
    
    @objc func onProgressSliderDragging() {
        self.isSeeking = true
    }
    
    @objc func onProgressSliderDragEnd() {
        if self.isSeeking {
            self.isSeeking = false
        }
    }
    
    @IBAction func onProgressSliderValueChange(_ sender: UISlider) {
        self.previewPlayer.seek(to: Double(sender.value))
    }
    
}


extension CompositionPreviewViewController: VideoPlayerDelegate {
    private func updatePlayerTimeForNowTime(_ time: TimeInterval) {
        let timeFormatter = DateComponentsFormatter()
        timeFormatter.allowedUnits = [.second, .minute, .hour]
        timeFormatter.unitsStyle = .positional
        timeFormatter.zeroFormattingBehavior = .pad
        self.leftTimeLable.text = timeFormatter.string(from: time)
        self.rightTimeLable.text = timeFormatter.string(from: self.previewPlayer.duration)
        
        if !self.isSeeking {
            self.progressSlider.value = Float(time)
        }
    }
    
    func videoPlayerIsReadyToPlay(_ player: VideoPlayer) {
        updatePlayerTimeForNowTime(0)
        self.progressSlider.minimumValue = 0
        self.progressSlider.maximumValue = Float(self.previewPlayer.duration)
        self.progressSlider.value = 0
    }
    
    func videoPlayerIsFailed(_ player: VideoPlayer, with error: Error?) {
        
    }
    
    func videoPlayer(_ player: VideoPlayer, statusDidChange to: VideoPlayer.PlayerStatus) {
        switch to {
            case .playing:
                self.playButton.isSelected = true
                break
            case .pause(_):
                self.playButton.isSelected = false
                break
            
            default:
                break
        }
        
    }
    
    func videoPlayer(_ player: VideoPlayer, timeDidChange to: Double) {
        updatePlayerTimeForNowTime(to)
    }
    
    func videoPlayer(_ player: VideoPlayer, loadedTimeRangeDidChange to: [(Double, Double)]) {

    }
    
    
}



extension CompositionPreviewViewController {
    
    private func loadTestComposition(_ compeletion: @escaping ()->Void) {
        loadMainTrackItems()
        loadStickers()
        loadAudios()
        self.syncGroup.notify(queue: DispatchQueue.main) {
            compeletion()
        }
    }
    
    fileprivate func loadMainTrackItems() {
        let url_1 = Bundle.main.url(forResource: "cute", withExtension: "mp4")!
        let trackItem_1 = TransitionableVideoTrackItem(resource: AVAssetResource(url: url_1))
        trackItem_1.videoTransition = VideoTransitionEmpty()
        trackItem_1.volume = 0.5
        self.timeLine.addVideoItem(trackItem_1)
        self.syncGroup.enter()
        trackItem_1.prepare(progressHandler: nil) {(status, error) in
            if status != .availdable {
                print("resource unavailable, url: \(trackItem_1.resource!.resourceURL?.absoluteString ?? "nil")")
            }
            self.syncGroup.leave()
        }
        
        
        let url_2 = Bundle.main.url(forResource: "02_blackhole", withExtension: "mp4")!
        let trackItem_2 = TransitionableVideoTrackItem(resource: AVAssetResource(url: url_2))
        trackItem_2.videoTransition = VideoTransitionDissolve()
        trackItem_2.videoTransition?.duration = CMTime(seconds: 1, preferredTimescale: 600)
        trackItem_2.volume = 0.8
        if let videoConfig = trackItem_2.videoConfiguration as? BasicVideoConfiguration {
            videoConfig.filter = CIFilter(name: "CIPhotoEffectMono")
        }
        self.timeLine.addVideoItem(trackItem_2)
        self.syncGroup.enter()
        trackItem_2.prepare(progressHandler: nil) {(status, error) in
            if status != .availdable {
                print("resource unavailable, url: \(trackItem_2.resource!.resourceURL?.absoluteString ?? "nil")")
            }
            self.syncGroup.leave()
        }
        
        let url_3 = Bundle.main.url(forResource: "03_nebula", withExtension: "mp4")!
        let trackItem_3 = TransitionableVideoTrackItem(resource: AVAssetResource(url: url_3))
        trackItem_3.videoTransition = VideoTransitionPush()
        trackItem_3.videoTransition?.duration = CMTime(seconds: 1, preferredTimescale: 600)
        trackItem_3.volume = 0.7
        self.timeLine.addVideoItem(trackItem_3)
        self.syncGroup.enter()
        trackItem_3.prepare(progressHandler: nil) {(status, error) in
            if status != .availdable {
                print("resource unavailable, url: \(trackItem_3.resource!.resourceURL?.absoluteString ?? "nil")")
            }

            self.syncGroup.leave()
        }
        
        
        let url_4 = Bundle.main.url(forResource: "05_blackhole", withExtension: "mp4")!
        let trackItem_4 = TransitionableVideoTrackItem(resource: AVAssetResource(url: url_4))
        trackItem_4.videoTransition = VideoTransitionSwipe()
        trackItem_4.videoTransition?.duration = CMTime(seconds: 1, preferredTimescale: 600)
        self.timeLine.addVideoItem(trackItem_4)
        self.syncGroup.enter()
        trackItem_4.prepare(progressHandler: nil) {(status, error) in
            if status != .availdable {
                print("resource unavailable, url: \(trackItem_4.resource!.resourceURL?.absoluteString ?? "nil")")
            }
            self.syncGroup.leave()
        }
    }
    
    
    fileprivate func loadStickers() {
        
//        let image = StickerTrackItem(name: "fire.jpeg")
//        image.selectedTimeRange = CMTimeRange(start: CMTime(seconds: 1, preferredTimescale: 600),
//                                                duration: CMTime(seconds: 3, preferredTimescale: 600))
//        image.position = CGPoint(x: 100, y: 100)
//        self.timeLine.addStickerItem(image)
    }
    
    fileprivate func loadOverlayTrackItems() {
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
    
    
    fileprivate func loadAudios() {
        let url = Bundle.main.url(forResource: "02 Keep Going", withExtension: "m4a")!
        let music = AudioTrackItem(resource: AVAssetResource(url: url))
        music.selectedTimeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: 16, preferredTimescale: 600))
        self.timeLine.addAudioItem(music, at: CMTime(seconds: 18, preferredTimescale: 600))
        music.volume = 0.1
        self.syncGroup.enter()
        music.prepare(progressHandler: nil) { (status, error) in
            self.syncGroup.leave()
            if status == .unavailable {
                print("failed to load music, error: \(error!)")
            }
        }
    }
}

