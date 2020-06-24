//
//  VideoTrackProvider.swift
//  05_videoEditor
//
//  Created by sy on 2020/5/25.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation
import CoreImage

protocol VideoCompositionTackProvider: class {
    var numberOfVideoTracks: uint { get }
    @discardableResult
    func videoCompositionTrack(for composition: AVMutableComposition, at trackIndex: Int, preferredTrackID: Int) -> AVMutableCompositionTrack?
    func trackInfo(for trackIndex: Int) -> ResourceTrackInfo?
}


protocol VideoEffectProvider: class {
    func applyEffect(to frame: CIImage, renderSize: CGSize, atTime: CMTime) -> CIImage
}

protocol VideoProvider:VideoCompositionTackProvider, VideoEffectProvider, AudioProvider {
    
}

protocol TransitionableVideoProvider: VideoProvider {
    var videoTransition: VideoTransition? { get set }
}
