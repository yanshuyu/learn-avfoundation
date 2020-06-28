//
//  CGAffinTransform+extension.swift
//  05_videoEditor
//
//  Created by sy on 2020/6/25.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGAffineTransform {
    static func transform(rect: CGRect, aspectRatioFitToRect: CGRect) -> CGAffineTransform {
        let fitRect = CGRect.aspectFitRect(for: rect, fitedRect: aspectRatioFitToRect)
        return transform(from: rect, to: fitRect)
    }
    
    static func transform(rect: CGRect, aspectRatioFillToRect: CGRect) -> CGAffineTransform {
        let fillRect = CGRect.aspectRatioFillRect(for: rect, filledRect: aspectRatioFillToRect)
        return transform(from: rect, to: fillRect)
    }
    
    static func transform(rect: CGRect, stretchToRect: CGRect) -> CGAffineTransform {
        return transform(from: rect, to: stretchToRect)
    }
    
    static func transform(from srcRect: CGRect, to dstRect: CGRect) -> CGAffineTransform {
        let xScale = dstRect.width / srcRect.width
        let yScale = dstRect.height / srcRect.height
        let transform = CGAffineTransform.identity.translatedBy(x: dstRect.origin.x - srcRect.origin.x * xScale, y: dstRect.origin.y - srcRect.origin.y * yScale)
            .scaledBy(x: xScale, y: yScale)
        return transform
    }
}
