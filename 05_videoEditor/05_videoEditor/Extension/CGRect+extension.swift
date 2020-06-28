//
//  CGRect+extension.swift
//  05_videoEditor
//
//  Created by sy on 2020/6/25.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGRect {
    static func aspectFitRect(for rect: CGRect, fitedRect: CGRect) -> CGRect {
        let scale = min(fitedRect.width / rect.width, fitedRect.height / rect.height)
        let size = CGSize(width: rect.width * scale, height: rect.height * scale)
        return CGRect(x: fitedRect.midX - size.width * 0.5,
                      y: fitedRect.midY - size.height * 0.5,
                      width: size.width,
                      height: size.height)
    }
    
    static func aspectRatioFillRect(for rect: CGRect, filledRect: CGRect) -> CGRect {
        let scale = max(filledRect.width / rect.width, filledRect.height / rect.height)
        let size = CGSize(width: rect.width * scale, height: rect.height * scale)
        return CGRect(x: filledRect.midX - size.width * 0.5,
                      y: filledRect.midY - size.height * 0.5,
                      width: size.width,
                      height: size.height)
    }
    
}
