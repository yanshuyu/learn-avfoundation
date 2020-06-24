//
//  VEVideoCompositionInstraction.swift
//  05_videoEditor
//
//  Created by sy on 2020/6/22.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation
import CoreImage

class VEVideoCompositionInstruction: NSObject, AVVideoCompositionInstructionProtocol {
    var timeRange: CMTimeRange
    
    var enablePostProcessing: Bool = false
    
    var containsTweening: Bool = false
    
    var requiredSourceTrackIDs: [NSValue]?
    
    var passthroughTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
    
    var mainTrackIDs: [CMPersistentTrackID] = []
    
    var layerInstructios: [VEVideoCompositionLayerInstruction] = []
    
    init(timeRange: CMTimeRange, passThroughTrackID: CMPersistentTrackID) {
        self.timeRange = timeRange
        self.passthroughTrackID = passThroughTrackID
    }
    
    init(timeRange: CMTimeRange, trackIDs: [CMPersistentTrackID]) {
        self.timeRange = timeRange
        self.requiredSourceTrackIDs = trackIDs as [NSValue]
        self.containsTweening = trackIDs.count > 1 ? true : false
    }
        
    func renderCompostion(for request: AVAsynchronousVideoCompositionRequest) throws -> CIImage? {
        var mainLayers: [VEVideoCompositionLayerInstruction] = []
        var overlayLayers: [VEVideoCompositionLayerInstruction] = []
        
        self.layerInstructios.forEach({
            if self.mainTrackIDs.contains($0.trackID) {
                mainLayers.append($0)
            } else {
                overlayLayers.append($0)
            }
        })
        
        
        if mainLayers.count > 2 {
            throw CompositionError.invailedNumberOfMainTrackLayer
        }
        
        if mainLayers.count <= 0 {
            throw CompositionError.missingMainTrackLayer
        }
        
        var finalImage: CIImage?
        
        // transition
        if mainLayers.count == 2 {
            var srcLayer = mainLayers[0]
            var dstLayer = mainLayers[1]
            
            if srcLayer.videoProvider.startTimeInTrack > dstLayer.videoProvider.startTimeInTrack {
                srcLayer = mainLayers[1]
                dstLayer = mainLayers[0]
            }
            
            guard let srcPixelBuffer = request.sourceFrame(byTrackID: srcLayer.trackID),
                let dstPixelBuffer = request.sourceFrame(byTrackID: dstLayer.trackID) else {
                    throw CompositionError.failedToGetSourceFrame
            }
            
            var srcImage = generateSourceImage(from: srcPixelBuffer)
            var dstImage = generateSourceImage(from: dstPixelBuffer)
            
            srcImage = srcLayer.applyEffect(to: srcImage, renderSize: request.renderContext.size, atTime: request.compositionTime)
            dstImage = dstLayer.applyEffect(to: dstImage, renderSize: request.renderContext.size, atTime: request.compositionTime)
            
            if let transition = dstLayer.videoTransition {
                finalImage = transition.renderTransition(from: srcImage, to: dstImage, tweening: percentageForTime(request.compositionTime, in: self.timeRange))
            } else {
                finalImage = dstImage
            }
            
        } else {
            guard let pixelBuffer = request.sourceFrame(byTrackID: mainLayers[0].trackID) else {
                throw CompositionError.failedToGetSourceFrame
            }
            finalImage = mainLayers[0].applyEffect(to: generateSourceImage(from: pixelBuffer),
                                                   renderSize: request.renderContext.size,
                                                   atTime: request.compositionTime)

        }
        
        
        var prevImage = finalImage
        try overlayLayers.forEach({
            if let pixelBuffer = request.sourceFrame(byTrackID: $0.trackID) {
                let currentlayerImage = $0.applyEffect(to: generateSourceImage(from: pixelBuffer), renderSize: request.renderContext.size, atTime: request.compositionTime)
                prevImage = prevImage == nil ? currentlayerImage : currentlayerImage.composited(over: prevImage!)
            } else {
                throw CompositionError.failedToGetSourceFrame
            }
        })
        
        finalImage = prevImage
        
        return finalImage
    }
}



fileprivate func percentageForTime(_ time: CMTime, in range: CMTimeRange) -> Float {
    if range.containsTime(time) {
        let elapsed = CMTimeSubtract(time, range.start).seconds
        return Float(elapsed / range.duration.seconds)
    }
    return 0
}


fileprivate func generateSourceImage(from pixelBuffer: CVPixelBuffer) -> CIImage {
    var image = CIImage(cvPixelBuffer: pixelBuffer)
    let attr = CVBufferGetAttachments(pixelBuffer, .shouldPropagate) as? [ String : Any ]
    if let attr = attr, !attr.isEmpty {
        if let aspectRatioDict = attr[kCVImageBufferPixelAspectRatioKey as String] as? [ String : Any ], !aspectRatioDict.isEmpty {
            let width = aspectRatioDict[kCVImageBufferPixelAspectRatioHorizontalSpacingKey as String] as? CGFloat
            let height = aspectRatioDict[kCVImageBufferPixelAspectRatioVerticalSpacingKey as String] as? CGFloat
            if let width = width, let height = height,  width != 0 && height != 0 {
                image = image.transformed(by: CGAffineTransform.identity.scaledBy(x: width / height, y: 1))
            }
        }
    }
    return image
}
