//
//  CMTimeRange+Extension.swift
//  05_videoEditor
//
//  Created by sy on 2020/5/29.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import CoreMedia

extension CMTimeRange {
     func centerAlignToTime(_ time: CMTime) -> CMTimeRange?  {
        if self.isValid && !self.isEmpty && time.isValid {
            let offset = CMTimeAdd(CMTimeSubtract(self.start, time), CMTimeMakeWithSeconds(self.duration.seconds * 0.5, preferredTimescale:self.start.timescale))
            return CMTimeRangeMake(start: CMTimeSubtract(self.start, offset), duration: self.duration)
        }
        return nil
    }
    
    func centerTime() -> CMTime? {
        if self.isValid {
            return CMTimeAdd(self.start, CMTimeMultiplyByFloat64(self.duration, multiplier: 0.5))
        }
        return nil
    }
}

