//
//  Dictionary+extension.swift
//  05_videoEditor
//
//  Created by sy on 2020/6/24.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation

extension Dictionary where Key == CMTimeRange, Value == CompositionLayerInstuctionTimeSlice {
    func toTimeSlicesArray() -> [CompositionLayerInstuctionTimeSlice] {
        var timeSlices: [CompositionLayerInstuctionTimeSlice] = []
        self.forEach({timeSlices.append($0.value)})
        return timeSlices
    }
}
