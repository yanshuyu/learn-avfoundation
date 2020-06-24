//
//  AVAssetResource.swift
//  05_videoEditor
//
//  Created by sy on 2020/5/25.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation

class AVAssetResource: Resource {
    public class AVAssetResourceCanceller: Cancelable {
        weak var asset: AVAsset?
        
        init(asset: AVAsset) {
            self.asset = asset
        }

        func cancel() {
            asset?.cancelLoading()
        }
    }
    
    var resourceURL: URL? {
        return (self.asset as? AVURLAsset)?.url
    }
    
    var duration: CMTime = CMTime.zero
    
    var resourceStatus: ResourceStatus = .unavailable
    
    var resourceError: NSError?
    
    var asset: AVAsset?
    
    init(avasset: AVAsset) {
        self.asset = avasset
    }
    
    init(url: URL) {
        self.asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey : true])
    }
    
    required init() {
    }
    
    func tracks(for mediaType: AVMediaType) -> [AVAssetTrack] {
        guard let asset = self.asset,
            self.resourceStatus == .availdable else {
            return []
        }
        
        return asset.tracks(withMediaType: mediaType)
    }
    
    func trackInfo(for mediaType: AVMediaType, at trackIndex: Int) -> ResourceTrackInfo? {
        let mediaTracks = tracks(for: mediaType)
        guard trackIndex >= 0, trackIndex < mediaTracks.count else {
            return nil
        }
        
        let track = mediaTracks[trackIndex]
        return ResourceTrackInfo(timeRange: track.timeRange,
                                 preferredVolume: track.preferredVolume,
                                 naturalSize: track.naturalSize,
                                 preferredTransform: track.preferredTransform)
    }
    
    @discardableResult
    func load(progressHandler: ((Double) -> Void)? = nil, completionHandler: ((ResourceStatus, NSError?) -> Void)?) -> Cancelable? {
        guard let asset = self.asset else {
            return nil
        }
        
        if self.resourceStatus == .loading {
            return AVAssetResourceCanceller(asset: asset)
        }
        
        self.resourceStatus = .loading
        asset.loadValuesAsynchronously(forKeys: [#keyPath(AVAsset.tracks),
                                                 #keyPath(AVAsset.duration)]) { [weak self] in
                                                    guard let strongSelf = self else {
                                                        return
                                                    }
                                                    
                                                    if asset.statusOfValue(forKey: #keyPath(AVAsset.tracks), error: &strongSelf.resourceError) != .loaded
                                                    || asset.statusOfValue(forKey: #keyPath(AVAsset.duration), error: &strongSelf.resourceError) != .loaded{
                                                        completionHandler?(.unavailable, strongSelf.resourceError)
                                                        strongSelf.resetStatus()
                                                        return
                                                    }
                                                    strongSelf.updateStatus()
                                                    completionHandler?(strongSelf.resourceStatus, nil)
         
        }
        
        return AVAssetResourceCanceller(asset: asset)
    }
    
    
    private func resetStatus() {
        self.resourceStatus = .unavailable
        self.resourceError = nil
        self.duration = CMTime.zero
    }
    
    private func updateStatus() {
        if let asset = self.asset {
            self.resourceStatus = .availdable
            self.duration = asset.duration
            self.resourceError = nil
        }
    }
}
