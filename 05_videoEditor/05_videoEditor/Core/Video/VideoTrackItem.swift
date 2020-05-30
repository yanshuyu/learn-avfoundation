//
//  VideoTrackItem.swift
//  05_videoEditor
//
//  Created by sy on 2020/5/26.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation




class VideoTrackItem: AudioTrackItem, VideoProvider {
    
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
}
