//
//  VideoTrackItem.swift
//  05_videoEditor
//
//  Created by sy on 2020/5/26.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation
import CoreImage



class VideoTrackItem: AudioTrackItem, VideoProvider {
    
    init(resource: Resource, videoConfiguration: VideoConfiguration? = nil) {
        super.init(resource: resource)
    }
    
    required init() {
        super.init()
    }
    
    //
    // VideoProvider
    //
    var numberOfVideoTracks: uint {
        guard let res = self.resource,
            res.resourceStatus == .availdable else {
                return 0
        }
        return uint(res.tracks(for: .video).count)
    }
    
    @discardableResult
    func videoCompositionTrack(for composition: AVMutableComposition, at trackIndex: Int, preferredTrackID: Int) -> AVMutableCompositionTrack? {
        guard self.numberOfVideoTracks > 0 else {
            return nil
        }
        
        var compositionTrack = composition.track(withTrackID: CMPersistentTrackID(preferredTrackID))
        if compositionTrack == nil {
            compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: CMPersistentTrackID(preferredTrackID))
        }
        
        if let _ = compositionTrack {
            let mediaTrack = self.resource!.tracks(for: .video)[trackIndex]
            do {
                try compositionTrack!.insertTimeRange(self.selectedTimeRange, of: mediaTrack, at: self.startTimeInTrack)
                compositionTrack!.scaleTimeRange(CMTimeRangeMake(start: self.startTimeInTrack,duration: self.selectedTimeRange.duration),
                                                 toDuration: self.durationTimeInTrack)
            } catch {
                print("\(#function) ======= throw error: \(error)")
                return nil
            }
        }
        return compositionTrack
    }
    
    override func trackInfor(for mediaType: AVMediaType, at trackIndex: Int) -> ResourceTrackInfo? {
        if mediaType == .audio {
            return super.trackInfor(for: .audio, at: trackIndex)
        
        } else if mediaType == .video, let res = self.resource {
            return res.trackInfo(for: .video, at: trackIndex)
        }
        return nil
    }
    
    
    //
    // MARK: - VideoConfiguration
    //
    var videoConfiguration: VideoConfiguration = BasicVideoConfiguration()
    
    //
    // MARK:- VideoProcessingProvider
    //
    func processingFrame(_ frame: CIImage, renderSize: CGSize, atTime: CMTime) -> CIImage {
        return self.videoConfiguration.applyVideoConfiguration(to: frame,
                                                               atTime: atTime,
                                                               inTimeRange: self.timeRangeInTrack,
                                                               renderSize: renderSize)
    }
}
