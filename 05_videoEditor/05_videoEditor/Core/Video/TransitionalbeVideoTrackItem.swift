//
//  TransitionalbeVideoTrackItem.swift
//  05_videoEditor
//
//  Created by sy on 2020/5/26.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation


class TransitionableVideoTrackItem: VideoTrackItem, TransitionableVideoProvider {
    var videoTransition: VideoTransition? = VideoTransitionDissolve()
}
