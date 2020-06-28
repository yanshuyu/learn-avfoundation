//
//  CompositionTimeRangeProvider.swift
//  05_videoEditor
//
//  Created by sy on 2020/5/25.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation

protocol CompositionTimeRangeProvider: class {
    var startTimeInTrack: CMTime { get set }
    var durationTimeInTrack: CMTime { get }
}

extension CompositionTimeRangeProvider {
    var timeRangeInTrack: CMTimeRange {
        return CMTimeRangeMake(start: self.startTimeInTrack, duration: self.durationTimeInTrack)
    }
}

protocol CompositionTrackInfoProvider: class {
    func trackInfor(for mediaType: AVMediaType, at trackIndex: Int) -> ResourceTrackInfo?
}
