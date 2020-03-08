//
//  VideoPlayer.swift
//  06_videoPlayer-swift
//
//  Created by sy on 2020/3/6.
//  Copyright © 2020 sy. All rights reserved.
//
import UIKit
import AVFoundation

protocol VideoPlayerDelegate: class {
    func videoPlayerIsReadyToPlay(_ player: VideoPlayer)
    func videoPlayerIsFailed(_ player: VideoPlayer, with error: Error?)
    func videoPlayer(_ player: VideoPlayer, statusDidChange to: VideoPlayer.PlayerStatus)
    func videoPlayer(_ player: VideoPlayer, timeDidChange to: Double)
    func videoPlayer(_ player: VideoPlayer, loadedTimeRangeDidChange to: [(Double,Double)])
}


class VideoPlayer: NSObject {
    public enum PauseReason {
        case unstart
        case reachEnd
        case manual
    }
    
    public enum WaitingReason {
        case noItem
        case minimizeToStall
    }
    
    public enum PlayerStatus {
        case pause(PauseReason)
        case playing
        case waiting(WaitingReason)
        case failed
    }
    
    
    public weak var delegate: VideoPlayerDelegate?

    private var playerView = VideoPlayerView()
    public var view: UIView {
        return self.playerView
    }
    private var player = AVPlayer()
    private(set) var status: PlayerStatus = .pause(.unstart) {
        didSet {
            self.delegate?.videoPlayer(self, statusDidChange: self.status)
        }
    }
    
    //
    // MARK: - public attributes
    //
    public var isReadyToPlay: Bool {
        guard let curItem = self.player.currentItem else {
            return false
        }
        return curItem.status == .readyToPlay
    }
    public var duration: Double {
        if let item = self.player.currentItem {
            return item.duration.seconds
        }
        return 0
    }
    public var canPlayFastForward: Bool {
        if let item = self.player.currentItem {
            return item.canPlayFastForward
        }
        return false
    }
    public var canPlaySlowForward: Bool {
        if let item = self.player.currentItem {
            return item.canPlaySlowForward
        }
        return false
    }
    public var canPlayReverse: Bool {
        if let item = self.player.currentItem {
            return item.canPlayReverse
        }
        return false
    }
    public var videoGravity: AVLayerVideoGravity {
        get {
            return self.playerView.gravity
        }
        set {
            self.playerView.gravity = newValue
        }
    }
    public var rate: Float {
        get {
            return self.player.rate
        }
        set {
            self.player.rate = newValue
        }
    }
    public var isMuted: Bool {
        get {
            return self.player.isMuted
        }
        set {
            self.player.isMuted = newValue
        }
    }
    public var volume: Float {
        get {
            return self.player.volume
        }
        set {
            self.player.volume = newValue
        }
    }
    
    
    
    private var periodTimer: Any?
    
    private static var statusKeyPath = [ #keyPath(AVPlayer.timeControlStatus),
                               #keyPath(AVPlayer.currentItem.status),
                               #keyPath(AVPlayer.currentItem.loadedTimeRanges)]
    private static var statusContext: Int = 0
    
    //
    // MARK: - init and deinit
    //
    init(playerItem: AVPlayerItem?) {
        super.init()
        self.playerView.player = self.player
        self.playerView.gravity = .resizeAspect
        addPlayerKVO()
        if let item = playerItem {
            replace(withPlayItem: item)
        }
    }
    
    override convenience init() {
        self.init(playerItem: nil)
    }
    
    convenience init(asset: AVAsset?) {
        var playerItem: AVPlayerItem?
        if let ast = asset {
            playerItem = AVPlayerItem(asset: ast)
        }
        self.init(playerItem: playerItem)
    }
    
    convenience init(contentOfURL: URL?) {
        var asset: AVAsset?
        if let url = contentOfURL {
            asset = AVAsset(url: url)
        }
        self.init(asset: asset)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        removePlayerKVO()
    }
    
    //
    // MARK: - player playback control
    //
    public func replace(withPlayItem: AVPlayerItem) {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                  object: self.player.currentItem)
        self.player.replaceCurrentItem(with: withPlayItem)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playbackDidReachEnd(_:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: self.player.currentItem)
    }
    
    public func replace(withAsset: AVAsset) {
        replace(withPlayItem: AVPlayerItem(asset: withAsset))
    }
    
    public func replace(withContentOfURL: URL) {
        replace(withAsset: AVAsset(url: withContentOfURL))
    }
    
    public func play() {
        self.player.play()
    }
    
    public func pause() {
        self.player.pause()
    }
    
    
    public func seek(to time: Double) {
        self.player.seek(to: CMTime(seconds: time, preferredTimescale: self.player.currentItem!.duration.timescale))
    }
    
    public func seek(to time: Double, completionHandler: @escaping (Bool)->Void ) {
        self.player.seek(to: CMTime(seconds: time, preferredTimescale: self.player.currentItem!.duration.timescale),
                         completionHandler: completionHandler)
    }
    
    public func seekToPercent(_ percent: Double, completionHandler: ((Bool)->Void)? ) {
        let seconds = self.player.currentItem!.duration.seconds * percent
        if let ch = completionHandler {
            seek(to: seconds, completionHandler: ch)
        } else {
            seek(to: seconds)
        }
    }
    
    //
    // MARK: - media characteristic selection
    //
    public func currentSelectedMediaSelectionOptionForMediaCharacteristic(_ mc: AVMediaCharacteristic) -> AVMediaSelectionOption? {
        guard let item = self.player.currentItem,
            let grp = mediaSelectionGroupForMediaCharacteristic(mc) else {
            return nil
        }
        return item.currentMediaSelection.selectedMediaOption(in: grp)
    }
    public func mediaSelectionGroupForMediaCharacteristic(_ mcr: AVMediaCharacteristic) -> AVMediaSelectionGroup? {
        guard let item = self.player.currentItem else {
            return nil
        }
        return item.asset.mediaSelectionGroup(forMediaCharacteristic: mcr)
    }
    
    public func selectMediaCharacteristic(in group: AVMediaSelectionGroup, with option: AVMediaSelectionOption?) {
        guard let item = self.player.currentItem else {
            return
        }
        item.select(option, in: group)
    }
    
    //
    // MARK: - KVO
    //
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if context != &VideoPlayer.statusContext {
            return super.observeValue(forKeyPath: keyPath,
                                      of: object,
                                      change: change,
                                      context: context)
        }
        
        if keyPath == #keyPath(AVPlayer.timeControlStatus) {
            switch self.player.timeControlStatus {
                case .playing:
                    self.status = .playing
                    break
                case .paused:
                    if case PlayerStatus.pause(.reachEnd) = self.status {
                        break
                    }
                    if self.isReadyToPlay {
                        self.status = .pause(.manual)
                    }
                    break
                case .waitingToPlayAtSpecifiedRate:
                    switch self.player.reasonForWaitingToPlay! {
                        case .noItemToPlay:
                            self.status = .waiting(.noItem)
                            break
                        case .toMinimizeStalls:
                            self.status = .waiting(.minimizeToStall)
                            break
                        default:
                            break
                    }
                    break
                default:
                    break
            }
            
            
        } else if keyPath == #keyPath(AVPlayer.currentItem.status) {
            if let curItem = self.player.currentItem {
                if curItem.status == .failed {
                    self.status = .failed
                    self.delegate?.videoPlayerIsFailed(self, with: self.player.currentItem?.error)
                } else if curItem.status == .readyToPlay {
                    self.delegate?.videoPlayerIsReadyToPlay(self)
                }
            }
        } else if keyPath == #keyPath(AVPlayer.currentItem.loadedTimeRanges) {
            guard let item = self.player.currentItem else {
                return
            }
            var ranges = [(Double,Double)]()
            for range in item.loadedTimeRanges {
                ranges.append((range.timeRangeValue.start.seconds, range.timeRangeValue.duration.seconds))
            }
            self.delegate?.videoPlayer(self, loadedTimeRangeDidChange: ranges)
        }
    }
    
    //
    // MARK: - helper
    //
    private func addPlayerKVO() {
        if let _ = self.periodTimer {
            return
        }
        
        for keyPath in VideoPlayer.statusKeyPath {
            self.player.addObserver(self, forKeyPath: keyPath,
                                    options: [.initial, .new],
                                    context: &VideoPlayer.statusContext)
        }
    
        self.periodTimer = self.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 600),
                                            queue: DispatchQueue.main) { [weak self] (time) in
                                                guard let strongSelf = self else {
                                                    return
                                                }
                                                strongSelf.delegate?.videoPlayer(strongSelf, timeDidChange: time.seconds)
                                                
        }
    }
    
    private func removePlayerKVO() {
        guard let pt = self.periodTimer else {
            return
        }
        
        for keyPath in VideoPlayer.statusKeyPath {
            self.player.removeObserver(self, forKeyPath: keyPath, context: &VideoPlayer.statusContext)
        }
        self.player.removeTimeObserver(pt)
        self.periodTimer = nil
    }
    
    @objc private func playbackDidReachEnd(_ notification: Notification) {
        self.status = .pause(.reachEnd)
    }

}
