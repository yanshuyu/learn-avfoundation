//
//  TimeLine.swift
//  05_videoEditor
//
//  Created by sy on 2020/5/25.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation

protocol TimeLine {
    var canvasProvider: CanvasProvider? { get set }
    
    var isEmpty: Bool { get }
    
    var videoItemCount: Int { get }
    
    var overItemCount: Int { get }
    
    var audioItemCount: Int { get }
    
    var stickerItemCount: Int { get }
    
    var totalItemCount: Int { get }
    
    func mainTrackItems() -> [TransitionableVideoProvider]
    func overlayTrackItems() -> [VideoProvider]
    func audioTrackItems() -> [AudioProvider]
    func stickerItems() -> [StickerProvider]
    
    func addVideoItem(_ videoItem: TransitionableVideoProvider)
    func addVideoItems(_ videoItems: [TransitionableVideoProvider])
    func removeVideoItem(_ videoItem: TransitionableVideoProvider)
    func removeAllVideoItems()
    
    func addOverlayItem(_ overlayItem: VideoProvider, at time: CMTime?)
    func addOverlayItems(_ overlayItems: [VideoProvider])
    func removeOverlayItem(_ overlayItem: VideoProvider)
    func removeAllOverlayItems()
    
    func addAudioItem(_ audioItem: AudioProvider, at time: CMTime?)
    func addAudioItems(_ audioItems: [AudioProvider])
    func removeAudioItem(_ audioItem: AudioProvider)
    func removeAllAudioItems()
    
    func addStickerItem(_ sticker: StickerProvider, at time: CMTime?)
    func addStickerItem(_ sticker: StickerProvider)
    func removeStickerItem(_ sticker: StickerProvider)
    func removeAllStickerItems()
    
    func removeAllItems()
    
    func updateTimeRanges()
    func performBatchUpdate(_ updateBlock: ()->Void)
    
}


extension TimeLine {
    var totalItemCount: Int {
        return self.videoItemCount + self.overItemCount + self.audioItemCount + self.stickerItemCount
    }
    
    var isEmpty: Bool {
        return self.totalItemCount <= 0
    }
}
