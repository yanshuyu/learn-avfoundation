//
//  AudioProvider.swift
//  05_videoEditor
//
//  Created by sy on 2020/5/25.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation

protocol AudioCompositionTrackProvider: CompositionTrackInfoProvider {
    var numberOfAudioTracks: uint { get }
    @discardableResult
    func audioCompositionTrack(for composition: AVMutableComposition, at trackIndex: Int, preferredTrackID: Int) -> AVMutableCompositionTrack?
}


protocol AudioMixerProvider {
    func configrueAudioMix(with parameters: AVMutableAudioMixInputParameters)
}

protocol AudioProvider: CompositionTimeRangeProvider, AudioCompositionTrackProvider, AudioMixerProvider {

}

