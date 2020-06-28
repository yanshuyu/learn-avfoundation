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
    
    func sliceTimeRanges(by: CMTimeRange) -> [CMTimeRange] {
        let intersection = self.intersection(by)
        guard intersection.duration.seconds > 0 else {
            return [self]
        }
        
        var slices: [CMTimeRange] = []
        let mostLeft = self.start < by.start ? self.start : by.start
        let mostRight = self.end > by.end ? self.end : by.end
        
        let leftSlice = CMTimeRange(start: mostLeft, end: intersection.start)
        if leftSlice.duration.seconds > 0 {
            slices.append(leftSlice)
        }
        slices.append(intersection)
        let rightSlice = CMTimeRange(start: intersection.end, end: mostRight)
        if rightSlice.duration.seconds > 0 {
            slices.append(rightSlice)
        }
        
        return slices
    }
    
    func subtractSubRange(_ timeRange: CMTimeRange) -> [CMTimeRange] {
        let intersection = self.intersection(timeRange)
        guard intersection.duration.seconds > 0 else {
            return [self]
        }
        
        var remainderslices: [CMTimeRange] = []
        let leftRange = CMTimeRange(start: self.start, end: intersection.start)
        let rightRange = CMTimeRange(start: intersection.end, end: self.end)
        
        if leftRange.duration.seconds > 0 {
            remainderslices.append(leftRange)
        }
        
        if rightRange.duration.seconds > 0 {
            remainderslices.append(rightRange)
        }
        
        return remainderslices
    }
    

}


extension CMTime: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.value)
        hasher.combine(self.timescale)
    }
}


extension CMTimeRange: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.start.value)
        hasher.combine(self.start.timescale)
        hasher.combine(self.duration.value)
        hasher.combine(self.duration.timescale)
    }
}


