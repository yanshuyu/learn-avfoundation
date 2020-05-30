//
//  TrackItem.swift
//  05_videoEditor
//
//  Created by sy on 2020/5/25.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation

class TrackItem: CompositionTimeRangeProvider {
    var startTimeInTrack: CMTime = CMTime.zero
    var durationTimeInTrack: CMTime  {
        return self.scaledTimeDuration
    }
    
    var resource: Resource?
    var isPrepared: Bool {
        guard let res = self.resource else {
            return false
        }
        return res.resourceStatus == .availdable
    }
    var selectedTimeRange: CMTimeRange = CMTimeRange.zero
    var speed: Float = 1.0
    var volum: Float = 1.0
    var scaledTimeDuration: CMTime {
        return CMTimeMultiplyByFloat64(self.selectedTimeRange.duration, multiplier: Float64(1 / self.speed))
    }
    
    required init() {
        
    }
    
    init(resource: Resource) {
        self.resource = resource
    }
    
    @discardableResult
    func prepare(progressHandler: ((Double)->Void)? = nil, compeletionHandler: ((ResourceStatus, NSError?)->Void)? = nil ) -> Cancelable? {
        if self.isPrepared {
            return nil
        }
        
        let canceller = self.resource?.load(progressHandler: progressHandler,
                                            completionHandler: { [weak self] (status, error) in
                                                guard let strongSelf = self,
                                                    let res = strongSelf.resource,
                                                    status == .availdable else {
                                                        compeletionHandler?(status, error)
                                                        return
                                                }
                                                strongSelf.selectedTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: res.duration)
                                                compeletionHandler?(status, error)
                                                
        })
        return canceller
    }
}
