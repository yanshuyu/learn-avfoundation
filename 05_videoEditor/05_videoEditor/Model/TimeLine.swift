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
    var isEmpty: Bool { get }
    
    func mainTrackItems() -> [TransitionableVideoProvider]
    func overlayTrackItems() -> [VideoProvider]
    func audioTrackItems() -> [AudioProvider]
    
    func addVideoItem(_ videoItem: TransitionableVideoProvider)
    func addVideoItems(_ videoItems: [TransitionableVideoProvider])
    
    func addOverlayItem(_ overlayItem: VideoProvider, at time: CMTime?)
    func addOverlayItems(_ overlayItems: [VideoProvider])
    
    func addAudioItem(_ audioItem: AudioProvider, at time: CMTime?)
    func addAudioItems(_ audioItems: [AudioProvider])
    
    func removeVideoItem(_ videoItem: TransitionableVideoProvider)
    func removeOverlayItem(_ overlayItem: VideoProvider)
    func removeAudioItem(_ audioItem: AudioProvider)
    
    func removeAllVideoItems()
    func removeAllOverlayItems()
    func removeAllAudioItems()
    func removeAllItems()
    
    func updateTimeRanges()
    func performBatchUpdate(_ updateBlock: ()->Void)
    
}
