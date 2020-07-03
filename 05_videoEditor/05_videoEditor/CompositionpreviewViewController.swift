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
        self.syncGroup.notify(queue: DispatchQueue.main) {
            compeletion()
        }
    }
    
    fileprivate func loadMainTrackItems() {
        var url: URL
        var trackItem: TransitionableVideoTrackItem
        
        url = Bundle.main.url(forResource: "cute", withExtension: "mp4")!
        trackItem = TransitionableVideoTrackItem(resource: AVAssetResource(url: url))
        trackItem.videoTransition = VideoTransitionEmpty()
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
        trackItem.videoTransition?.duration = CMTime(seconds: 1, preferredTimescale: 600)
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
        
        url = Bundle.main.url(forResource: "03_nebula", withExtension: "mp4")!
        trackItem = TransitionableVideoTrackItem(resource: AVAssetResource(url: url))
        trackItem.videoTransition = VideoTransitionPush()
        trackItem.videoTransition?.duration = CMTime(seconds: 1, preferredTimescale: 600)
        self.timeLine.addVideoItem(trackItem)
        self.syncGroup.enter()
        trackItem.prepare(progressHandler: nil) {(status, error) in
            if status != .availdable {
                print("resource unavailable, url: \(trackItem.resource!.resourceURL?.absoluteString ?? "nil")")
            }
            self.syncGroup.leave()
        }
        
        
        url = Bundle.main.url(forResource: "05_blackhole", withExtension: "mp4")!
        trackItem = TransitionableVideoTrackItem(resource: AVAssetResource(url: url))
        trackItem.videoTransition = VideoTransitionSwipe()
        trackItem.videoTransition?.duration = CMTime(seconds: 1, preferredTimescale: 600)
        self.timeLine.addVideoItem(trackItem)
        self.syncGroup.enter()
        trackItem.prepare(progressHandler: nil) {(status, error) in
            if status != .availdable {
                print("resource unavailable, url: \(trackItem.resource!.resourceURL?.absoluteString ?? "nil")")
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
}

