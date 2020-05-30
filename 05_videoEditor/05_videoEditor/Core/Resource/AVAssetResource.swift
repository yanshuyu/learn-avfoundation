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
    
    var natureSize: CGSize = CGSize.zero
    
    var duration: CMTime = CMTime.zero
    
    var preferredTransform: CGAffineTransform = .identity
    
    var preferredVolum: Float = 1.0
    
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
                                                        strongSelf.resetStatus()
                                                        completionHandler?(.unavailable, strongSelf.resourceError)
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
        self.natureSize = CGSize.zero
        self.duration = CMTime.zero
    }
    
    private func updateStatus() {
        if let asset = self.asset {
            self.resourceStatus = .availdable
            self.duration = asset.duration
            self.natureSize = asset.tracks(withMediaType: .video).first?.naturalSize ?? CGSize.zero
            self.resourceError = nil
        }
    }
}
