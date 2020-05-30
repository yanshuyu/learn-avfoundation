//
//  VideoTrackProvider.swift
//  05_videoEditor
//
//  Created by sy on 2020/5/25.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation

protocol VideoCompositionTackProvider: class {
    var numberOfVideoTracks: uint { get }
    @discardableResult
    func videoCompositionTrack(for composition: AVMutableComposition, at trackIndex: Int, preferredTrackID: Int) -> AVMutableCompositionTrack?
}


protocol VideoProvider:VideoCompositionTackProvider, AudioProvider {
    
}

protocol TransitionableVideoProvider: VideoProvider {
    var transitionDuration: CMTime { get set }
    var videoTransitionIdentifier: String { get set }
    var audioTransitionIdentifier: String { get set }
}
