//
//  VideoConfigurationPotocol.swift
//  05_videoEditor
//
//  Created by sy on 2020/6/25.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation
import CoreImage

protocol VideoConfiguration {
    func applyVideoConfiguration(to frame: CIImage,
                                 atTime: CMTime,
                                 inTimeRange: CMTimeRange,
                                 renderSize: CGSize) -> CIImage
}


class BasicVideoConfiguration: VideoConfiguration {
    enum ContentMode {
        case aspectRatioFit
        case aspectRationFill
        case stretch
    }
    
    var renderArea: CGRect?
    
    var contentMode: ContentMode = .aspectRatioFit
    
    var transform: CGAffineTransform?
    
    var opacity: Float = 1
    
    var filter: CIFilter?
    
    func applyVideoConfiguration(to frame: CIImage, atTime: CMTime, inTimeRange: CMTimeRange, renderSize: CGSize) -> CIImage {
        let canvas = self.renderArea ?? CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height)
        var processedImage = frame
        
        
        if let customFilter = self.filter {
            customFilter.setValue(processedImage, forKey: kCIInputImageKey)
            processedImage = customFilter.outputImage ?? processedImage
        }
        
        
        switch self.contentMode {
            case .aspectRatioFit:
                processedImage = processedImage.transformed(by: CGAffineTransform.transform(rect: processedImage.extent, aspectRatioFitToRect: canvas)).cropped(to: canvas)
                break
            
            case .aspectRationFill:
                processedImage = processedImage.transformed(by: CGAffineTransform.transform(rect: processedImage.extent, aspectRatioFillToRect: canvas)).cropped(to: canvas)
                break
            
            case .stretch:
                processedImage = processedImage.transformed(by: CGAffineTransform.transform(rect: processedImage.extent, stretchToRect: canvas)).cropped(to: canvas)
                break
        }
        
        if let customTransform = self.transform {
            var transform = CGAffineTransform.identity.translatedBy(x: -(processedImage.extent.origin.x + processedImage.extent.width * 0.5), y: -(processedImage.extent.origin.y + processedImage.extent.height * 0.5))
            transform = transform.concatenating(customTransform)
            transform.concatenating(CGAffineTransform(translationX: processedImage.extent.origin.x + processedImage.extent.width * 0.5, y: processedImage.extent.origin.y + processedImage.extent.height * 0.5))
            processedImage = processedImage.transformed(by: transform)
        }
        
        processedImage = processedImage.setOpacity(CGFloat(self.opacity))
        
        return processedImage
    }
}
