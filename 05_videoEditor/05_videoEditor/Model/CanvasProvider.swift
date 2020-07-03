//
//  CanvasProvider.swift
//  05_videoEditor
//
//  Created by sy on 2020/6/29.
//  Copyright © 2020 sy. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage

protocol CanvasProvider: class {
    func drawCanvas(for frame: CIImage, atTime: CMTime, renderSize: CGSize) -> CIImage
}


class BasicVanvas: CanvasProvider {
    enum VanvasMode {
        case solidColor
        case blurBackground
    }
    
    
    var mode: VanvasMode = .solidColor
    
    var canvasColor: UIColor = .black
    
    var canvasBlurness: Double = 32
    
    func drawCanvas(for frame: CIImage, atTime: CMTime, renderSize: CGSize) -> CIImage {
        if self.mode == .solidColor {
            return CIImage(color: CIColor(color: self.canvasColor)).cropped(to: CGRect(origin: .zero, size: renderSize))
        } else if self.mode == .blurBackground {
            let transform = CGAffineTransform.transform(rect: frame.extent, aspectRatioFillToRect: CGRect(origin: .zero, size: renderSize))
            return frame.transformed(by: transform).applyingGaussianBlur(sigma: canvasBlurness)
        }
        
        return frame
    }
}
