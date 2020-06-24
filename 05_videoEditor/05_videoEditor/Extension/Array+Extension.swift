//
//  Array+Extension.swift
//  05_videoEditor
//
//  Created by sy on 2020/5/29.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation

extension Array where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}


extension Array where Element == VEVideoCompositionLayerInstruction {
    func sortedLayerInstructions() -> [VEVideoCompositionLayerInstruction] {
        return self.sorted { (left, right) -> Bool in
            return left.videoProvider.startTimeInTrack < right.videoProvider.startTimeInTrack
        }
    }
}


extension Array where Element == CompositionLayerInstuctionTimeSlice {
    
    func sortedTimeSlices() -> [CompositionLayerInstuctionTimeSlice] {
        return self.sorted { (left, right) -> Bool in
            return left.timeRange.start < right.timeRange.start
        }
    }
    
    func toTimeSlicesDictionary() -> [CMTimeRange:CompositionLayerInstuctionTimeSlice] {
        var timeSlicesDict: [CMTimeRange:CompositionLayerInstuctionTimeSlice] = [:]
        self.forEach({ timeSlicesDict[$0.timeRange] = $0 })
        return timeSlicesDict
    }
}
