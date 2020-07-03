//
//  AudioTrackItem.swift
//  05_videoEditor
//
//  Created by sy on 2020/5/26.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation


class AudioTrackItem: TrackItem, AudioProvider {
    override var durationTimeInTrack: CMTime {
        return self.scaledTimeDuration
    }
    
    var speed: Float = 1.0
    
    var volume: Float = 1.0
        
    var scaledTimeDuration: CMTime {
        return CMTimeMultiplyByFloat64(self.selectedTimeRange.duration, multiplier: Float64(1 / self.speed))
    }

    
    //
    // MARK: - AudioCompositionTrackProvider
    //
    var numberOfAudioTracks: uint {
        guard let res = self.resource,
            res.resourceStatus == .availdable else {
                return 0
        }
        
        return uint(res.tracks(for: .audio).count)
    }
    
    func audioCompositionTrack(for composition: AVMutableComposition, at trackIndex: Int, preferredTrackID: Int) -> AVMutableCompositionTrack? {
        guard self.numberOfAudioTracks > 0 else {
            return nil
        }
        
        var compositionTrack = composition.track(withTrackID: CMPersistentTrackID(preferredTrackID))
        if compositionTrack == nil {
            compositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID(preferredTrackID))
        }
        
        if let _ = compositionTrack {
            let mediaTrack = self.resource!.tracks(for: .audio)[trackIndex]
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
    

    func trackInfor(for mediaType: AVMediaType, at trackIndex: Int) -> ResourceTrackInfo? {
        if mediaType == .audio, let res = self.resource {
            return res.trackInfo(for: .audio, at: trackIndex)
        }
        return nil
    }
    
    //
    // MARK: - AudioMixerProvider
    //
    func configrueAudioMix(with parameters: AVMutableAudioMixInputParameters) {
        
    }
}
