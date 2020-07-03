//
//  VECompositionGenerator.swift
//  05_videoEditor
//
//  Created by sy on 2020/5/26.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation


typealias CompositionLayerInstuctionTimeSlice = (timeRange: CMTimeRange, layerInstructions: [VEVideoCompositionLayerInstruction])

class VECompositionGenerator: CompositionGenerator {
    private var timeLine: TimeLine {
        didSet {
            prepareToBuild()
        }
    }
    
    private var composition: AVComposition?
    private var videoComposition: AVVideoComposition?
    private var audioMix: AVAudioMix?
    private var animationLayer: CALayer?
    
    var renderSize: CGSize {
        didSet {
            prepareToBuild()
        }
    }
    var frameDuration: CMTime {
        didSet {
            prepareToBuild()
        }
    }
    
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
    
    required init(timeLine: TimeLine, renderSize: CGSize = CGSize(width: 1280, height: 720), frameDuration: CMTime = CMTime(value: 1, timescale: 30)) {
        self.timeLine = timeLine
        self.renderSize = renderSize
        self.frameDuration = frameDuration
        self.tracksIDCounter = TRACKSIDCOUNTERINIT
    }
    
    //
    // MARK: Public API
    //
    func buildPlayerItem() -> AVPlayerItem? {
        buildComposition()
        buildVideoComposition()
        buildAudioMix()
        buildAnimations()
        
        guard let comp = self.composition else {
            return nil
        }
         
        let playerItem = AVPlayerItem(asset: comp)
        playerItem.videoComposition = self.videoComposition
        playerItem.audioMix = self.audioMix
        playerItem.animationLayer = self.animationLayer
        
        return  playerItem
    }
    
    func buildExportSessiom() -> AVAssetExportSession? {
        return nil
    }
    
    func buildImageGenerator() -> AVAssetImageGenerator? {
        return nil
    }
    
    //
    // MARK: - Private API
    //
    private func buildComposition() {
        if self.composition != nil  {
            return
        }
        
        prepareToBuild()

        let comp = AVMutableComposition(urlAssetInitializationOptions: [AVURLAssetPreferPreciseDurationAndTimingKey:true])
        
        // main track items
        self.timeLine.mainTrackItems().enumerated().forEach { (offset, videoItem) in
            var videoTrackID: Int?
            var audioTrackIDs: [Int] = []
            
            if videoItem.numberOfVideoTracks > 0 {
                let preferredTrackID = calcTrackIDForMainTrackItem(with: .video, offset: offset, index: 0)
                #if DEBUG
                precondition(preferredTrackID != -1)
                #endif
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
                #if DEBUG
                precondition(preferredTrackID != -1)
                #endif
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
                #if DEBUG
                precondition(videoTrackID != -1)
                #endif
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
                #if DEBUG
                precondition(audioTrackID != -1)
                #endif
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
                #if DEBUG
                precondition(preferredTrackId != -1)
                #endif
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
    
    private func buildVideoComposition() {
        if self.videoComposition != nil {
            return
        }
        
        guard self.composition != nil else {
            fatalError("Composition is nil!")
        }
        
        var compositionLayerInstructions: [VEVideoCompositionLayerInstruction] = []
        self.mainVideoTracksInfo.forEach { (trackID, trackSegments) in
            for videoProvider in trackSegments {
                let layerInst = VEVideoCompositionLayerInstruction(trackID: CMPersistentTrackID(trackID), videoProvider: videoProvider)
                layerInst.trackInfo = videoProvider.trackInfor(for: .video, at: 0)
                compositionLayerInstructions.append(layerInst)
            }
        }
        
        self.overlayVideoTracksInfo.forEach { (trackID, trackSegments) in
            for videoProvider in trackSegments {
                let layerInst = VEVideoCompositionLayerInstruction(trackID: CMPersistentTrackID(trackID), videoProvider: videoProvider)
                layerInst.trackInfo = videoProvider.trackInfor(for: .video, at: 0)
                compositionLayerInstructions.append(layerInst)
            }
        }
        
        let sortedLayerInsts = compositionLayerInstructions.sortedLayerInstructions()        
        let layerInstructionTimeSlices = calcTimeSlicesForCompositionLayerInstructions(sortedLayerInsts)
        let mainTrackIDs = self.mainVideoTracksInfo.keys.map({ CMPersistentTrackID($0) })
        var compositionInstructions: [VEVideoCompositionInstruction] = []
        
        layerInstructionTimeSlices.forEach { (timeRange, layerInstructions) in
            let trackIDs = layerInstructions.map({ $0.trackID })
            let inst = VEVideoCompositionInstruction(timeRange: timeRange, trackIDs: trackIDs)
            inst.mainTrackIDs = mainTrackIDs
            inst.layerInstructios = layerInstructions
            inst.canvasProvider = self.timeLine.canvasProvider
            compositionInstructions.append(inst)
        }
        
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = compositionInstructions
        videoComposition.customVideoCompositorClass = VEVideoCompositor.self
        videoComposition.frameDuration = self.frameDuration
        videoComposition.renderSize = self.renderSize
        
        self.videoComposition = videoComposition
    }
    
    private func buildAudioMix() {
        if self.audioMix != nil {
            return
        }
        
        guard self.mainAudioTracksInfo.count + self.overlayAudioTracksInfo.count + self.audioTracksInfo.count > 0 else { return }
        
        var audioMixInputParams = [AVMutableAudioMixInputParameters]()
        let audioMixConfigure: (Int, [AudioProvider])->Void = { [weak self] (trackID, audioProviders) in
            guard let strongSelf = self else { return }
            if let audioCompTrack = strongSelf.composition!.track(withTrackID: CMPersistentTrackID(trackID)) {
                let params = AVMutableAudioMixInputParameters(track: audioCompTrack)
                audioProviders.forEach { $0.configrueAudioMix(with: params) }
                audioMixInputParams.append(params)
            }
        }
        
        self.mainAudioTracksInfo.forEach { audioMixConfigure($0, $1) }
        self.overlayAudioTracksInfo.forEach {audioMixConfigure($0, $1)}
        self.audioTracksInfo.forEach { audioMixConfigure($0, $1)}
        
        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = audioMixInputParams
        self.audioMix = audioMix
    }
    
    private func buildAnimations() {
        guard self.composition != nil else {
            fatalError("Composition is nil!")
        }
        
        let animlayer = CALayer()
        animlayer.bounds = CGRect(origin: .zero, size: self.renderSize)
        self.timeLine.stickerItems().forEach { stickerProvider in
            animlayer.addSublayer(stickerProvider.animationLayer(for: self.renderSize))
        }
        self.animationLayer = animlayer
    }
    
    
    //
    // MARK: - Helper
    //
    private func prepareToBuild() {
        self.composition = nil
        self.videoComposition = nil
        self.audioMix = nil
        self.animationLayer = nil
        
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
            guard index < 10 else { return -1 }
            return (offset % 2 + 1) * 10 + index
        } else if mediaType == .audio {
            guard index < 100 else { return -1 }
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
    
    private func calcTimeSlicesForCompositionLayerInstructions(_ layerInstructions: [VEVideoCompositionLayerInstruction]) -> [CompositionLayerInstuctionTimeSlice] {
        var layerInstTimeSlices: [CompositionLayerInstuctionTimeSlice] = []
        layerInstructions.forEach { (newAddLayerInst) in
            let newAddTimeRange = newAddLayerInst.videoProvider.timeRangeInTrack
            var remainderTimeRanges: [CMTimeRange] = [newAddTimeRange]
            var layerInstTimeSlicesDict = layerInstTimeSlices.toTimeSlicesDictionary()
        
            
            layerInstTimeSlices.forEach { (sliceTimeRange, sliceLayerInsts) in
                let intersection = sliceTimeRange.intersection(newAddTimeRange)
                if intersection.duration.seconds > 0 {
                    layerInstTimeSlicesDict[sliceTimeRange] = nil
                    let newSliceTimeRanges = sliceTimeRange.sliceTimeRanges(by: newAddTimeRange)
                    newSliceTimeRanges.forEach { (slice) in
                        if sliceTimeRange.containsTimeRange(slice) {
                            if newAddTimeRange.containsTimeRange(slice) {
                                layerInstTimeSlicesDict[slice] = newCompositionLayerInstuctionTimeSlice(slice, sliceLayerInsts + [newAddLayerInst])
                                remainderTimeRanges = remainderTimeRanges.flatMap({$0.subtractSubRange(slice)})
                            } else {
                                layerInstTimeSlicesDict[slice] = newCompositionLayerInstuctionTimeSlice(slice, sliceLayerInsts)
                            }
                        }
                    }
                }
            }
            
            remainderTimeRanges.forEach({ layerInstTimeSlicesDict[$0] = newCompositionLayerInstuctionTimeSlice($0, [newAddLayerInst]) })
            layerInstTimeSlices = layerInstTimeSlicesDict.toTimeSlicesArray().sortedTimeSlices()
        }
        
        return layerInstTimeSlices
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
                        let videoSegments = videoItems
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
                            let audioSegments = audioItems
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
                str += "-----------------------------------------\n"
            }
        }
        
        if let _ = self.videoComposition {
            str += "Video Composition:\n"
            self.videoComposition?.instructions.forEach({ (inst) in
                if let inst = inst as? VEVideoCompositionInstruction {
                    let trackIDs: [CMPersistentTrackID] = (inst.requiredSourceTrackIDs as? [CMPersistentTrackID] ?? [])
                    str += "[\(inst.timeRange.start.seconds) - \(inst.timeRange.end.seconds)(\(trackIDs))] "
                }
            })
            str += "\n"
        }
        return str
    }
}


fileprivate func newCompositionLayerInstuctionTimeSlice(_ timeRange: CMTimeRange, _ layerInstructions: [VEVideoCompositionLayerInstruction]) -> CompositionLayerInstuctionTimeSlice {
    return (timeRange: timeRange, layerInstructions: layerInstructions)
}
