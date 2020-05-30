//
//  VETimeLine.swift
//  05_videoEditor
//
//  Created by sy on 2020/5/25.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation

class VETimeLine: TimeLine {
    private var mainTracks: [TransitionableVideoProvider] = []
    
    private var overlayTracks: [VideoProvider] = []
    
    private var audioTracks: [AudioProvider] = []
    
    
    func mainTrackItems() -> [TransitionableVideoProvider] {
        return self.mainTracks
    }
    
    func overlayTrackItems() -> [VideoProvider] {
        return self.overlayTracks
    }
    
    func audioTrackItems() -> [AudioProvider] {
        return self.audioTracks
    }
    
    func addVideoItem(_ videoItem: TransitionableVideoProvider) {
        if let _ = self.mainTracks.first(where: {$0 === videoItem}) {
            return
        }
        self.mainTracks.append(videoItem)
    }
    
    func addVideoItems(_ videoItems: [TransitionableVideoProvider]) {
        videoItems.forEach { addVideoItem($0) }
        
    }
    
    func addOverlayItem(_ overlayItem: VideoProvider, at time: CMTime? = nil) {
        if let _ = self.overlayTracks.first(where: { $0 === overlayItem }) {
            return
        }
        var mutableOverlayItem = overlayItem
        if let time = time {
            mutableOverlayItem.startTimeInTrack = time
        }
        self.overlayTracks.append(mutableOverlayItem)

    }
    
    func addOverlayItems(_ overlayItems: [VideoProvider]) {
        overlayItems.forEach { addOverlayItem($0) }
    }
    
    func addAudioItem(_ audioItem: AudioProvider, at time: CMTime? = nil) {
        if let _ = self.audioTracks.first(where: { $0 === audioItem }) {
            return
        }
        var mutableAudioItem = audioItem
        if let time = time {
            mutableAudioItem.startTimeInTrack = time
        }
        self.audioTracks.append(mutableAudioItem)

    }
    
    func addAudioItems(_ audioItems: [AudioProvider]) {
        audioItems.forEach { addAudioItem($0) }
    }
    
    func removeVideoItem(_ videoItem: TransitionableVideoProvider) {
        if let idx = self.mainTracks.firstIndex(where: { $0 === videoItem}) {
            self.mainTracks.remove(at: idx)
        }
    }
    
    func removeOverlayItem(_ overlayItem: VideoProvider) {
        if let idx = self.overlayTracks.firstIndex(where: { $0 === overlayItem }) {
            self.overlayTracks.remove(at: idx)
        }
    }
    
    func removeAudioItem(_ audioItem: AudioProvider) {
        if let idx = self.mainTracks.firstIndex(where: { $0 === audioItem }) {
            self.audioTracks.remove(at: idx)
        }
    }
    
    func removeAllVideoItems() {
        self.mainTracks = []
    }
    
    func removeAllOverlayItems() {
        self.overlayTracks  = []
    }
    
    func removeAllAudioItems() {
        self.audioTracks = []
    }
    
    func removeAllItems() {
        removeAllVideoItems()
        removeAllOverlayItems()
        removeAllAudioItems()
    }
    
    func reloadTimeRanges() {
        // layout main tracks, ignore transition duration
        var cursorTime: CMTime = .zero
        for offset in 0..<self.mainTracks.count {
            var curItem = self.mainTracks[offset]
            var transitionDur = curItem.transitionDuration
            if offset == 0 {
                transitionDur = .zero
            }
            cursorTime = CMTimeSubtract(cursorTime, transitionDur)
            precondition(cursorTime.isValid)
            curItem.startTimeInTrack = cursorTime
            cursorTime = CMTimeAdd(cursorTime, curItem.durationTimeInTrack)
        }
        
        // vaildated transition duration
        for offset in 0..<self.mainTracks.count {
            var current = self.mainTracks[offset]
            var prevItem: TransitionableVideoProvider?
            var nextItem: TransitionableVideoProvider?
            
            if offset > 0 {
                prevItem = self.mainTracks[offset - 1]
            }
            if offset < self.mainTracks.count - 1 {
                nextItem = self.mainTracks[offset + 1]
            }
            if let prev = prevItem, let next = nextItem {
                let intersectRange = prev.timeRangeInTrack.intersection(next.timeRangeInTrack)
                if intersectRange.duration.seconds > 0 {
                    offsetTimeRanges(from: offset+1, by: intersectRange.duration)
                    current.startTimeInTrack = current.timeRangeInTrack.centerAlignToTime(prev.timeRangeInTrack.end)!.start
                    current.transitionDuration = CMTimeMakeWithSeconds(current.durationTimeInTrack.seconds * 0.5, preferredTimescale: 600)
                    next.transitionDuration = current.transitionDuration
                }
            }
            
            if let next = nextItem, prevItem == nil {
                if next.timeRangeInTrack.containsTimeRange(current.timeRangeInTrack) {
                    offsetTimeRanges(from: offset+1, by:CMTimeSubtract(current.timeRangeInTrack.centerTime()!, next.startTimeInTrack))
                    next.transitionDuration = CMTimeMakeWithSeconds(current.durationTimeInTrack.seconds * 0.5, preferredTimescale: 600)
                }
            }
            
            
            if let prev = prevItem, nextItem == nil {
                if prev.timeRangeInTrack.containsTimeRange(current.timeRangeInTrack) {
                    let target = current.timeRangeInTrack.centerAlignToTime(prev.timeRangeInTrack.end)!
                    offsetTimeRanges(from: offset, by: CMTimeSubtract(target.start, current.startTimeInTrack))
                    current.transitionDuration = CMTimeMakeWithSeconds(current.durationTimeInTrack.seconds * 0.5, preferredTimescale: 600)
                }
            }
        }
    }
    
    func performBatchUpdate(_ updateBlock: () -> Void) {
        updateBlock()
        reloadTimeRanges()
    }
    
    

    
}


extension VETimeLine {
    private func offsetTimeRanges(from index: Int, by time: CMTime) {
        for offset in index..<self.mainTracks.count {
            var current = self.mainTracks[offset]
            current.startTimeInTrack = CMTimeAdd(current.startTimeInTrack, time)
        }
    }
}
