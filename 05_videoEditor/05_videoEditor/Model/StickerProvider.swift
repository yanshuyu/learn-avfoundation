//
//  StickerProvider.swift
//  05_videoEditor
//
//  Created by sy on 2020/7/2.
//  Copyright © 2020 sy. All rights reserved.
//

import UIKit

protocol StickerProvider: CompositionTimeRangeProvider {
    func animationLayer(for renderSize: CGSize) -> CALayer
}
