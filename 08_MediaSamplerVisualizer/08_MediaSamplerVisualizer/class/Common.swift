//
//  common.swift
//  08_MediaSamplerVisualizer
//
//  Created by sy on 2020/3/24.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation


public enum AssetLoadStatus {
    case unkown
    case loading
    case completed
    case failed
    case cancelled
    case paused
}

public protocol Cancelable {
    func cancel()
}

public protocol AssetLoadable {
    typealias AssetLoadCompletionHandler = (AssetLoadStatus, Error?) -> Void
    func load(_ asset: AVAsset, queue: OperationQueue?, completionHandler: Self.AssetLoadCompletionHandler?) -> Cancelable?
    
}
