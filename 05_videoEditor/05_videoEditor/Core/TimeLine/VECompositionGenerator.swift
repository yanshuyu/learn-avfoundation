//
//  VECompositionGenerator.swift
//  05_videoEditor
//
//  Created by sy on 2020/5/26.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation

class VECompositionGenerator: CompositionGenerator {
    private var timeLine: TimeLine
    private var composition: AVComposition?
    
    private var TRACKSIDCOUNTERINIT  = 1000
    private var tracksIDCounter: Int
    private var nextTrackID: Int {
        let currentID = self.tracksIDCounter
        self.tracksIDCounter += 1
        return currentID
    }
    private var mainAVTracksIDMapping: [Int:[Int]] = [:]
    private var overlayAVTracksIDMapping: [Int:[Int]] = [:]
    private var audioTracksID: [Int] = []
    
    private var mainVideoTracksInfo: [Int:[TransitionableVideoProvider]] = [:]
    private var mainAudioTracksInfo: [Int:[AudioProvider]] = [:]
    private var overlayVideoTracksInfo: [Int: [VideoProvider]] = [:]
    private var overlayAudioTracksInfo: [Int: [AudioProvider]] = [:]
    private var audioTracksInfo: [Int:[AudioProvider]] = [:]
    
    required init(timeLine: TimeLine) {
        self.timeLine = timeLine
        self.tracksIDCounter = TRACKSIDCOUNTERINIT
    }
    
    func buildPlayerItem() -> AVPlayerItem? {
        prepareToBuild()
        buildComposition()
        guard let comp = self.composition else {
            return nil
        }
        return AVPlayerItem(asset: comp)
    }
    
    func buildExportSessiom() -> AVAssetExportSession? {
        return nil
    }
    
    func buildImageGenerator() -> AVAssetImageGenerator? {
        return nil
    }
    
    private func buildComposition() {
        let comp = AVMutableComposition(urlAssetInitializationOptions: [AVURLAssetPreferPreciseDurationAndTimingKey:true])
        
        // main track items
        self.timeLine.mainTrackItems().enumerated().forEach { (offset, videoItem) in
            var videoTrackID: Int?
            var audioTrackIDs: [Int] = []
            
            if videoItem.numberOfVideoTracks > 0 {
                let preferredTrackID = calcTrackIDForMainTrackItem(with: .video, offset: offset, index: 0)
                precondition(preferredTrackID != -1)
                if let _ = videoItem.videoCompositionTrack(for: comp, at: 0, preferredTrackID: preferredTrackID) {
                    if self.mainVideoTracksInfo[preferredTrackID] == nil {
                        self.mainVideoTracksInfo[preferredTrackID] = []
                    }
                    self.mainVideoTracksInfo[preferredTrackID]?.append(videoItem)
                    videoTrackID = preferredTrackID
                }
            }
            
            for audioTrackIdx in 0..<videoItem.numberOfAudioTracks {
                let preferredTrackID = calcTrackIDForMainTrackItem(with: .audio, offset: offset, index: Int(audioTrackIdx))
                precondition(preferredTrackID != -1)
                if let _ = videoItem.audioCompositionTrack(for: comp, at: Int(audioTrackIdx), preferredTrackID: preferredTrackID) {
                    if self.mainAudioTracksInfo[preferredTrackID] == nil {
                        self.mainAudioTracksInfo[preferredTrackID] = []
                    }
                    self.mainAudioTracksInfo[preferredTrackID]?.append(videoItem)
                    audioTrackIDs.append(preferredTrackID)
                }
            }
            
            if let _ = videoTrackID, audioTrackIDs.count > 0 {
                audioTrackIDs = (self.mainAVTracksIDMapping[videoTrackID!] ?? [] + audioTrackIDs).unique()
                self.mainAVTracksIDMapping[videoTrackID!] = audioTrackIDs
            }
        }
        
        // overlay track items
        self.timeLine.overlayTrackItems().forEach { (overlayItem) in
            var videoTrackID: Int = -1
            if overlayItem.numberOfVideoTracks > 0 {
                videoTrackID = calcTrackIDForOverlayTrackItem(for: comp, mediaType: .video, timeRange: overlayItem.timeRangeInTrack)
                precondition(videoTrackID != -1)
                if let _ = overlayItem.videoCompositionTrack(for: comp, at: 0, preferredTrackID: videoTrackID) {
                    if self.overlayVideoTracksInfo[videoTrackID] == nil {
                        self.overlayVideoTracksInfo[videoTrackID] = []
                    }
                    self.overlayVideoTracksInfo[videoTrackID]?.append(overlayItem)
                }
            }
            
            var audioTrackIDs = [Int]()
            for idx in 0..<overlayItem.numberOfAudioTracks {
                let audioTrackID = calcTrackIDForOverlayTrackItem(for: comp,
                                                              mediaType: .audio,
                                                              timeRange: nil,
                                                              hint: videoTrackID,
                                                              index: Int(idx))
                precondition(audioTrackID != -1)
                if let _ = overlayItem.audioCompositionTrack(for: comp, at: Int(idx), preferredTrackID: audioTrackID) {
                    if self.overlayAudioTracksInfo[audioTrackID] == nil {
                        self.overlayAudioTracksInfo[audioTrackID] = []
                    }
                    self.overlayAudioTracksInfo[audioTrackID]?.append(overlayItem)
                    audioTrackIDs.append(audioTrackID)
                }
            }
            
            audioTrackIDs = (self.overlayAVTracksIDMapping[videoTrackID] ?? [] + audioTrackIDs).unique()
            self.overlayAVTracksIDMapping[videoTrackID] = audioTrackIDs
        }
        
        // audio track items
        self.timeLine.audioTrackItems().forEach { (audioItem) in
            for idx in 0..<audioItem.numberOfAudioTracks {
                let preferredTrackId = calcTrackIDForAudioTrackItem()
                precondition(preferredTrackId != -1)
                if let _ = audioItem.audioCompositionTrack(for: comp, at: Int(idx), preferredTrackID: preferredTrackId) {
                    if self.audioTracksInfo[preferredTrackId] == nil {
                        self.audioTracksInfo[preferredTrackId] = []
                    }
                    self.audioTracksInfo[preferredTrackId]?.append(audioItem)
                    self.audioTracksID.append(preferredTrackId)
                }
            }
        }
        
        self.composition = comp
    }
    
    //
    // MARK: - Helper
    //
    private func prepareToBuild() {
        self.tracksIDCounter = TRACKSIDCOUNTERINIT
        self.mainAVTracksIDMapping = [:]
        self.overlayAVTracksIDMapping = [:]
        self.audioTracksID = []
        
        self.mainVideoTracksInfo = [:]
        self.mainAudioTracksInfo = [:]
        self.overlayVideoTracksInfo = [:]
        self.overlayAudioTracksInfo = [:]
        self.audioTracksInfo = [:]
    }
    
    private func calcTrackIDForMainTrackItem(with mediaType: AVMediaType, offset: Int, index: Int) -> Int {
        if mediaType == .video {
            precondition(index < 10)
            return (offset % 2 + 1) * 10 + index
        } else if mediaType == .audio {
            precondition(index < 100)
            return (offset % 2 + 1) * 100 + index
        }
        return -1
    }
    
    private func calcTrackIDForOverlayTrackItem(for composition: AVComposition,
                                                mediaType: AVMediaType,
                                                timeRange: CMTimeRange?,
                                                hint: Int? = nil,
                                                index: Int? = nil) -> Int {
        if mediaType == .video {
            if let timeRange = timeRange {
                if let foundedIdx = self.overlayVideoTracksInfo.firstIndex(where: { ( _, overlayItems) -> Bool in
                    var videoSegments = overlayItems
                    videoSegments.sort { (lhs, rhs) -> Bool in
                        return lhs.timeRangeInTrack.start.seconds < rhs.timeRangeInTrack.start.seconds
                    }
                    
                    if let fstSegment = videoSegments.first,
                        timeRange.end.seconds < fstSegment.timeRangeInTrack.start.seconds {
                        return true
                    }
                    if let lstSegment = videoSegments.last,
                        timeRange.start.seconds > lstSegment.timeRangeInTrack.end.seconds {
                        return true
                    }
                    
                    if videoSegments.count < 2 {
                        return false
                    }
                    
                    for offset in 0..<videoSegments.count-1 {
                        let currentSegment = videoSegments[offset]
                        let nextSegment = videoSegments[offset + 1]
                        if currentSegment.timeRangeInTrack.end.seconds < timeRange.start.seconds &&
                            timeRange.end.seconds < nextSegment.timeRangeInTrack.start.seconds {
                            return true
                        }
                    }
                    
                    return false
                }) {
                    return self.overlayVideoTracksInfo[foundedIdx].key
                }
            }
            return self.nextTrackID
            
        } else if mediaType == .audio {
            if let videoTrack = hint,
                let index = index,
                let audioTracks = self.overlayAVTracksIDMapping[videoTrack] {
                if index < audioTracks.count {
                    return audioTracks[index]
                }
            }
            return self.nextTrackID
        }
        
        return -1
    }
    
    private func calcTrackIDForAudioTrackItem() -> Int {
        return self.nextTrackID
    }

}


extension VECompositionGenerator: CustomDebugStringConvertible {
    var debugDescription: String {
        var str = ""
        if let _ = self.composition {
            str += "Composition:\n"
            if self.mainAVTracksIDMapping.count > 0 {
                str += "-------------Main Tracks---------------\n"
                self.mainAVTracksIDMapping.forEach { (videoTrackID, audioTrackIDs) in
                    if let videoItems = self.mainVideoTracksInfo[videoTrackID] {
                        var videoSegments = videoItems
                        videoSegments.sort { (lhs, rhs) -> Bool in
                            return lhs.timeRangeInTrack.start.seconds < rhs.timeRangeInTrack.start.seconds
                        }
                        str += "v:\(videoTrackID) [ ";
                        videoSegments.enumerated().forEach { (offset, segment) in
                            str += "(\(segment.timeRangeInTrack.start.seconds)s,\(segment.timeRangeInTrack.end.seconds)s)"
                            if offset < videoSegments.count - 1 {
                                str += ", "
                            }
                        }
                        str += " ]\n"
                    }
                    
                    audioTrackIDs.enumerated().forEach { (offset, audioTrackID) in
                        if let audioItems = self.mainAudioTracksInfo[audioTrackID] {
                            var audioSegments = audioItems
                            audioSegments.sort { (lhs, rhs) -> Bool in
                                return lhs.timeRangeInTrack.start.seconds < rhs.timeRangeInTrack.start.seconds
                            }
                            str += "a:\(audioTrackID) [ ";
                            audioSegments.enumerated().forEach { (offset, segment) in
                                str += "(\(segment.timeRangeInTrack.start.seconds)s,\(segment.timeRangeInTrack.end.seconds)s)"
                                if offset < audioSegments.count - 1 {
                                    str += ", "
                                }
                            }
                            str += " ]\n"
                            
                        }
                    }
                    
                }
                str += "-----------------------------------------\n"
            }
            
            if self.overlayAVTracksIDMapping.count > 0 {
                str += "-------------Overlay Tracks---------------\n"
                self.overlayAVTracksIDMapping.forEach { (videoTrackID, audioTrackIDs) in
                    if let videoItems = self.overlayVideoTracksInfo[videoTrackID] {
                        var videoSegments = videoItems
                        videoSegments.sort { (lhs, rhs) -> Bool in
                            return lhs.timeRangeInTrack.start.seconds < rhs.timeRangeInTrack.start.seconds
                        }
                        str += "v:\(videoTrackID) [ ";
                        videoSegments.enumerated().forEach { (offset, segment) in
                            str += "(\(segment.timeRangeInTrack.start.seconds)s,\(segment.timeRangeInTrack.end.seconds)s)"
                            if offset < videoSegments.count - 1 {
                                str += ", "
                            }
                        }
                        str += " ]\n"
                    }
                    
                    audioTrackIDs.enumerated().forEach { (offset, audioTrackID) in
                        if let audioItems = self.overlayAudioTracksInfo[audioTrackID] {
                            var audioSegments = audioItems
                            audioSegments.sort { (lhs, rhs) -> Bool in
                                return lhs.timeRangeInTrack.start.seconds < rhs.timeRangeInTrack.start.seconds
                            }
                            str += "a:\(audioTrackID) [ ";
                            audioSegments.enumerated().forEach { (offset, segment) in
                                str += "(\(segment.timeRangeInTrack.start.seconds)s,\(segment.timeRangeInTrack.end.seconds)s)"
                                if offset < audioSegments.count - 1 {
                                    str += ", "
                                }
                            }
                            str += " ]\n"
                            
                        }
                    }
                    
                }
                str += "-----------------------------------------\n"
            }
            
            if self.audioTracksID.count > 0 {
                str += "---------------Audio Tracks--------------\n"
                self.audioTracksID.forEach { (audioTrackID) in
                    if let audioItems = self.audioTracksInfo[audioTrackID] {
                        var audioSegments = audioItems
                        audioSegments.sort { (lhs, rhs) -> Bool in
                            return lhs.timeRangeInTrack.start.seconds < rhs.timeRangeInTrack.start.seconds
                        }
                        str += "a:\(audioTrackID) [ ";
                        audioSegments.enumerated().forEach { (offset, segment) in
                            str += "(\(segment.timeRangeInTrack.start.seconds)s,\(segment.timeRangeInTrack.end.seconds)s)"
                            if offset < audioSegments.count - 1 {
                                str += ", "
                            }
                        }
                        str += " ]\n"
                        
                    }
                }
            }
        }
        return str
    }
}
