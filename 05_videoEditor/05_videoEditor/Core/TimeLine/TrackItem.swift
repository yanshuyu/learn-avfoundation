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
    
    var durationTimeInTrack: CMTime {
        return self.selectedTimeRange.duration
    }
    
    var resource: Resource?
    
    var selectedTimeRange: CMTimeRange = CMTimeRange.zero 
    
    var isPrepared: Bool {
        guard let res = self.resource else {
            return false
        }
        return res.resourceStatus == .availdable
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
        
        let compeletion: (ResourceStatus, NSError?)->Void = { status, error in
            if let _ = self.resource, status == .availdable {
                if self.selectedTimeRange == CMTimeRange.zero {
                    self.selectedTimeRange = CMTimeRange(start: .zero, duration: self.resource!.duration)
                    
                }
            }
            compeletionHandler?(status, error)
        }
        
        return self.resource?.load(progressHandler: progressHandler, completionHandler: compeletion)
    }
}
