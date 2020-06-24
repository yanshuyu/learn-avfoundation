//
//  Resource.swift
//  05_videoEditor
//
//  Created by sy on 2020/5/25.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation

enum ResourceStatus {
    case unavailable
    case loading
    case availdable
}


protocol Cancelable {
    func cancel()
}


struct ResourceTrackInfo {
    var timeRange: CMTimeRange
    var preferredVolume: Float
    var naturalSize: CGSize
    var preferredTransform: CGAffineTransform
}

protocol Resource {
    var resourceURL: URL? { get }
    var duration: CMTime { get }
    var resourceStatus: ResourceStatus { set get }
    var resourceError: NSError? { get set }
    
    func tracks(for mediaType: AVMediaType) -> [AVAssetTrack]
    
    func trackInfo(for mediaType: AVMediaType, at trackIndex: Int) -> ResourceTrackInfo?
    
    @discardableResult
    func load(progressHandler: ((Double)->Void)?, completionHandler: ((ResourceStatus, NSError?)->Void)?) -> Cancelable?
}
