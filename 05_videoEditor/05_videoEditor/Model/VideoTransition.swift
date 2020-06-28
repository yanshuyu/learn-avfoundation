//
//  VideoTransition.swift
//  05_videoEditor
//
//  Created by sy on 2020/6/21.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation
import CoreImage

protocol VideoTransition: class {
    var identifier: String { get }
    var duration: CMTime { set get }
    
    func renderTransition(from sourceFrame: CIImage, to destinationFrame: CIImage, tweening: Float, renderSize: CGSize) -> CIImage
}

class VideoTransitionEmpty: VideoTransition {
    var identifier: String {
        return String(describing: self)
    }
    
    var duration: CMTime
    
    convenience init() {
        self.init(duration: CMTimeMakeWithSeconds(1, preferredTimescale: 600))
    }
    
    init(duration: CMTime) {
        self.duration = duration
    }
    
    func renderTransition(from sourceFrame: CIImage, to destinationFrame: CIImage, tweening: Float, renderSize: CGSize) -> CIImage {
        return destinationFrame
    }
    
    
}


class VideoTransitionDissolve: VideoTransition {
    var identifier: String {
        return String(describing: self)
    }
    
    var duration: CMTime = CMTime(seconds: 1, preferredTimescale: 600)
    
    func renderTransition(from sourceFrame: CIImage, to destinationFrame: CIImage, tweening: Float, renderSize: CGSize) -> CIImage {
        return sourceFrame.applyingFilter("CIDissolveTransition", parameters: [kCIInputTargetImageKey:destinationFrame,
                                                                               kCIInputTimeKey:tweening as NSNumber])
    }
}


class VideoTransitionSwipe: VideoTransition {
    var identifier: String {
        return String(describing: self)
    }
    
    var duration: CMTime = CMTime(seconds: 1, preferredTimescale: 600)
    
    func renderTransition(from sourceFrame: CIImage, to destinationFrame: CIImage, tweening: Float, renderSize: CGSize) -> CIImage {
        return sourceFrame.applyingFilter("CISwipeTransition", parameters: [kCIInputTargetImageKey:destinationFrame,
                                                                            kCIInputExtentKey:CIVector(x: destinationFrame.extent.origin.x,
                                                                                                       y: destinationFrame.extent.origin.y,
                                                                                                       z: destinationFrame.extent.width,
                                                                                                       w: destinationFrame.extent.height),
                                                                            kCIInputTimeKey:tweening,
                                                                            kCIInputWidthKey:destinationFrame.extent.width])
        
    }
}


class VideoTransitionPush: VideoTransition {
    public enum PushDirection {
        case left
        case right
        case up
        case down
    }
    
    var identifier: String {
        return String(describing: self)
    }
    
    var duration: CMTime = CMTime(seconds: 1, preferredTimescale: 600)
    
    var direction: PushDirection = .left
    
    func renderTransition(from sourceFrame: CIImage, to destinationFrame: CIImage, tweening: Float, renderSize: CGSize) -> CIImage {
        switch self.direction {
            case .left:
                let srcTransform = CGAffineTransform(translationX: renderSize.width * CGFloat(-tweening), y: 0)
                let dstTransform = CGAffineTransform(translationX: renderSize.width * CGFloat(1 - tweening), y: 0)
                return destinationFrame.transformed(by: dstTransform)
                    .composited(over: sourceFrame.transformed(by: srcTransform))
                    .cropped(to: CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height))
            
            case .right:
                let srcTransform = CGAffineTransform(translationX: renderSize.width * CGFloat(tweening), y: 0)
                let dstTransform = CGAffineTransform(translationX: renderSize.width * CGFloat(tweening - 1), y: 0)
                return destinationFrame.transformed(by: dstTransform)
                    .composited(over: sourceFrame.transformed(by: srcTransform))
                    .cropped(to: CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height))
            
            case .up:
                let srcTransform = CGAffineTransform(translationX: 0, y: renderSize.height * CGFloat(tweening))
                let dstTransform = CGAffineTransform(translationX: 0, y: renderSize.height * CGFloat(tweening - 1))
                return destinationFrame.transformed(by: dstTransform)
                    .composited(over: sourceFrame.transformed(by: srcTransform))
                    .cropped(to: CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height))
            
            case .down:
                let srcTransform = CGAffineTransform(translationX: 0, y: renderSize.height * CGFloat(-tweening))
                let dstTransform = CGAffineTransform(translationX: 0, y: renderSize.height * CGFloat(1 - tweening ))
                return destinationFrame.transformed(by: dstTransform)
                    .composited(over: sourceFrame.transformed(by: srcTransform))
                    .cropped(to: CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height))
            
        }
    }
}



class VideoTransitionPageCurl: VideoTransition {
    var identifier: String {
        return String(describing: self)
    }
    
    var duration: CMTime = CMTime(seconds: 1, preferredTimescale: 600)
    
    func renderTransition(from sourceFrame: CIImage, to destinationFrame: CIImage, tweening: Float, renderSize: CGSize) -> CIImage {
        return sourceFrame.applyingFilter("CIPageCurlTransition", parameters: [kCIInputTargetImageKey:destinationFrame,
                                                                               kCIInputExtentKey: CIVector(x: destinationFrame.extent.origin.x,
                                                                                                           y: destinationFrame.extent.origin.y,
                                                                                                           z: destinationFrame.extent.width,
                                                                                                           w: destinationFrame.extent.height),
                                                                               kCIInputTimeKey:tweening,
                                                                               kCIInputAngleKey: Float.pi])
    }
    
    
}
